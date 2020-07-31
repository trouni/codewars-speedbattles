<template>
  <div>
    <div v-if="moderator" class="mt-3">
      <h3><strong class="highlight">Profile settings</strong></h3>
      <!-- <small>You are moderator for this war room.</small> -->
    </div>
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
      <small>Toggle music, sound effects and voice announcements.<span v-if="!settings.room.sound"><br><em>Sound settings have been partially disabled for this war room.</em></span></small>
    </div>
    <!-- <div class="mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Default syntax highlighter</h5>
        <select v-model="hljsLang" class="flex-grow-1 ml-3">
          <option v-for="(key, lang_name) in settings.room.codewars_langs" :value="lang_name" :key="key">{{ key }}</option>
        </select>
      </div>
      <small>Select a default language to write code blocks.</small>
    </div> -->
    <div class="webhook-settings mb-5">
      <div class="d-flex justify-content-between">
        <h5>Codewars webhook
          <sup>
            <span v-if="settings.user.connected_webhook" class="badge badge-success">Connected</span>
            <span v-else class="badge badge-danger animated flash delay-1s">Required</span>
          </sup>
        </h5>
        <std-button
          v-if="!settings.user.connected_webhook"
          @click.native="showWebhookHelp"
          fa-icon="fas fa-question-circle"
          small>Help</std-button>
      </div>
      <div v-if="settings.user.connected_webhook">
        <small>Last call received {{ formatDate(settings.user.last_webhook_at) }}.</small>
        <span class="d-flex justify-content-center my-3">
          <std-button @click.native="$root.$emit('update-settings', { user: { connected_webhook: false, last_webhook_at: null } })" small>Reconnect the webhook</std-button>
        </span>
      </div>
      <div v-else>
        <small>Add these settings to your Codewars account in order to automatically detect when you have completed a challenge.</small>
        <div class="d-flex flex-column align-items-center justify-content-center my-3">
          
          <a href="https://www.codewars.com/users/edit#forgot_password" target="_blank">
            <std-button @click.native="$root.$emit('update-settings', { user: { connected_webhook: false, last_webhook_at: null } })" small>Open Codewars settings</std-button>
          </a>
        </div>
        <div class="form-group">
          <small>
            <label for="webhook_url" class="form-control-label w-100 text-center">Payload url</label>
            <div class="custom-tooltip clickable copyable webhook-border payload-url-color" :data-tooltip="tooltipText" @mouseleave="resetTooltip">
              <input
                @click="copyToClipboard($event)"
                type="text"
                name="webhook_url"
                class="form-control text-center"
                readonly
                :value="`https://${host}/webhook`"
              />
            </div>
            <label for="webhook_url" class="form-control-label w-100 text-center mt-3">Secret</label>
            <div class="custom-tooltip clickable copyable webhook-border secret-color" :data-tooltip="tooltipText" @mouseleave="resetTooltip">
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
    <div class="form-group mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Low-res Theme</h5>
        <std-button
          @click.native="$root.$emit('toggle-low-res')"
          :fa-icon="`fas ${lowRes ? 'fa-adjust' : 'fa-image'}`"
        >{{ lowRes ? 'LOW RES' : 'STANDARD' }}</std-button>
      </div>
      <small>Alternative theme that removes transparency and other effects for slower devices.</small>
    </div>
    <div class="form-group mb-5">
      <div class="d-flex justify-content-around">
        <a href="/users/sign_out" data-method="delete">
          <std-button @click.native="cancel" fa-icon="fas fa-sign-out-alt" small>Sign out</std-button>
        </a>
        <a href="/rooms/">
          <std-button @click.native="cancel" fa-icon="fas fa-angle-double-left" small>Leave room</std-button>
        </a>
      </div>
    </div>
  </div>
</template>

<script>
import EventBus from '../../services/event_bus'

export default {
  name: 'user-settings',
  props: {
    settings: Object,
    moderator: {
      type: Boolean,
      default: false
    },
  },
  watch: {
    settings: {
      handler(newSettings) {
        this.displayName = newSettings.user.name
        this.hljsLang = newSettings.user.hljs_lang
        this.lowRes = newSettings.user.low_res_theme
      },
      deep: true
    }
  },
  data() {
    return {
      tooltipText: "Copy to clipboard",
      displayName: this.settings.user.name,
      hljsLang: this.settings.user.hljs_lang,
      lowRes: this.settings.user.low_res_theme,
      host: process.env.VUE_APP_HOST
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
          low_res_theme: this.lowRes,
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
    formatDate(dateString) {
      const date = new Date(dateString)
      const time = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:${String(date.getSeconds()).padStart(2, '0')}`
      const day = this.isSameDay(new Date, date) ? 'today' : `${date.toDateString()}`
      return `${day} at ${time}`
    },
    isSameDay(a, b) {
      return a.getFullYear() === b.getFullYear() &&
        a.getMonth() === b.getMonth() &&
        a.getDate()=== b.getDate()
    },
    showWebhookHelp() {
      let height = window.screen.height / 2
      window.open('/setup-webhook', 'setup_webhook', `resizable=0,width=${height * 2},height=${height},scrollbars=0,status=0,toolbar=0,location=0`);
    }
  }
}
</script>

<style>

</style>