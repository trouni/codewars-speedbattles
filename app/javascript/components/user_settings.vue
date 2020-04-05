<template>
  <div>
    <div class="form-group mt-3 mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0 no-wrap">Display name</h5>
        <input
          @keydown.enter="updateSettings"
          type="text"
          :placeholder="settings.user.username"
          class="form-control ml-3"
          v-model="displayName"
          maxlength="32"
        />
      </div>
      <small>By default, your Codewars username will be shown.</small>
    </div>
    <div class="form-group mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Audio</h5>
        <span class="d-flex justify-content-around flex-grow-1 ml-2">
          <std-button
            @click.native="$root.$emit('toggle-music')"
            :class="{'toggled-off': !settings.user.music}"
            :fa-icon="`fas ${settings.user.music ? 'fa-music' : 'fa-volume-mute'}`"
            :disabled="!settings.room.sound && !moderator"
          >Music {{settings.user.music ? 'ON' : 'OFF'}}</std-button>
          <std-button
            @click.native="$root.$emit('toggle-sound-fx')"
            :class="[{'toggled-off': !settings.user.sfx}]"
            :fa-icon="`fas ${settings.user.sfx ? 'fa-drum' : 'fa-volume-mute'}`"
          >Sound FX {{settings.user.sfx ? 'ON' : 'OFF'}}</std-button>
          <std-button
            @click.native="$root.$emit('toggle-voice')"
            :class="{'toggled-off': !settings.user.voice}"
            :fa-icon="`fas ${settings.user.voice ? 'fa-robot' : 'fa-volume-mute'}`"
            :disabled="!settings.room.sound && !moderator"
          >Voice {{settings.user.voice ? 'ON' : 'OFF'}}</std-button>
        </span>
      </div>
      <small>Toggle music, sound effects and voice announcements.<span v-if="!settings.room.sound"> Sound settings have been partially disabled for this war room.</span></small>
    </div>
    <div class="mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Default syntax highlighter</h5>
        <select v-model="hljsLang" class="flex-grow-1 ml-3">
          <option v-for="(lang, alias) in codewarsLangs" :value="lang" :key="alias">{{ alias }}</option>
        </select>
      </div>
      <small>Select a default language to write code blocks.</small>
    </div>
    <div class="webhook-settings mb-5">
      <h5>Codewars Webhook
        <sup>
          <span v-if="settings.user.connected_webhook" class="badge badge-success">Connected</span>
          <span v-else class="badge badge-danger">Not connected</span>
        </sup>
      </h5>
      <div v-if="settings.user.connected_webhook" class="d-flex justify-content-center">
        <std-button @click.native="$root.$emit('update-settings', { user: { connected_webhook: false } })" small>Reconnect the webhook</std-button>
      </div>
      <div v-else>
        <small>Add these settings to your Codewars account in order to automatically detect when you have completed a challenge.</small>
        <div class="d-flex flex-column align-items-center justify-content-center my-3">
          <a href="https://www.codewars.com/users/edit#forgot_password" target="_blank" class="button small">Update your Codewars settings</a>
        </div>
        <div class="form-group">
          <small>
            <label for="webhook_url" class="form-control-label w-100 text-center">Payload url</label>
            <div class="custom-tooltip clickable copyable" :data-tooltip="tooltipText" @mouseleave="resetTooltip">
              <input
                @click="copyToClipboard($event)"
                type="text"
                name="webhook_url"
                class="form-control text-center"
                readonly
                value="https://speedbattles.herokuapp.com/webhook"
              />
            </div>
            <label for="webhook_url" class="form-control-label w-100 text-center mt-3">Secret</label>
            <div class="custom-tooltip clickable copyable" :data-tooltip="tooltipText" @mouseleave="resetTooltip">
              <input
                @click="copyToClipboard($event)"
                type="text"
                name="webhook_secret"
                class="form-control text-center"
                readonly
                :value="settings.user.webhook_secret"
              />
            </div>
          </small>
        </div>
      </div>
    </div>
    <span class="d-flex justify-content-around mb-3">
      <a href="/users/sign_out" data-method="delete">
        <std-button @click.native="cancel" fa-icon="fas fa-sign-out-alt" small>Sign out</std-button>
      </a>
      <a href="/rooms/">
        <std-button @click.native="cancel" fa-icon="fas fa-angle-double-left" small>Leave room</std-button>
      </a>
    </span>
  </div>
</template>

<script>
import EventBus from '../services/event_bus'

export default {
  name: 'user-settings',
  props: {
    settings: Object,
    moderator: Boolean,
  },
  data() {
    return {
      tooltipText: "Copy to clipboard",
      displayName: this.settings.user.name,
      hljsLang: this.settings.user.hljs_lang,
      codewarsLangs: {
        '': '',
        'C': 'c',
        'C#': 'c#',
        'C++': 'c++',
        'Clojure': 'clj',
        'CoffeeScript': 'coffee',
        'Crystal': 'cr',
        'Dart': 'dart',
        'Elixir': 'elixir',
        'F#': 'fs',
        'Go': 'go',
        'Haskell': 'hs',
        'Java': 'java',
        'JavaScript': 'js',
        'PHP': 'php',
        'Python': 'py',
        'Ruby': 'rb',
        'Rust': 'rs',
        'Shell': 'shell',
        'SQL': 'sql',
        'Swift': 'swift',
        'TypeScript': 'ts',
      }
    }
  },
  computed: {
    updatedSettings() {
      return {
        user: {
          name: this.displayName,
          sfx: this.settings.user.sfx,
          voice: this.settings.user.voice,
          music: this.settings.user.music,
          hljs_lang: this.hljsLang,
        }
      }
    },
  },
  mounted() {
    EventBus.$on('submit', this.updateSettings)
    EventBus.$on('cancel', this.cancel)
  },
  methods: {
    cancel() {
      this.$root.$emit('close-modal')
    },
    updateSettings() {
      this.$root.$emit('update-settings', this.updatedSettings)
      this.$root.$emit('close-modal')
    },
    copyToClipboard(event) {
      event.target.select()
      document.execCommand('copy')
      this.tooltipText = 'Copied'
      if (window.getSelection) {window.getSelection().removeAllRanges();}
      else if (document.selection) {document.selection.empty();}
    },
    resetTooltip() {
      this.tooltipText = 'Copy to clipboard'
    },
  }
}
</script>

<style>

</style>