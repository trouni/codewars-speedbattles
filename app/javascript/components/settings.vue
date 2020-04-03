<template>
  <div class="d-flex flex-column h-100">
    <div class="flex-grow-1">
      <div class="form-group mb-3">
        <h5>Display name</h5>
        <small>Your Codewars username will be shown if you don't enter a display name.</small>
        <input
          @keydown.enter="updateSettings"
          type="text"
          class="form-control mt-3"
          v-model="displayName"
          maxlength="50"
        />
      </div>
      <div v-if="settings.room.sound || moderator" class="form-group mb-3">
      <h5>Audio</h5>
        <small>Activate/deactivate music and sound effects/announcements.</small>
        <span class="d-flex justify-content-around">
          <std-button
            @click.native="$root.$emit('toggle-music')"
            :class="{disabled: !settings.user.music}"
            :fa-icon="`fas ${settings.user.music ? 'fa-music' : 'fa-volume-mute'}`"
          >Music {{settings.user.music ? 'ON' : 'OFF'}}</std-button>
          <std-button @click.native="$root.$emit('toggle-sound-fx')" :class="{disabled: !settings.user.sfx}" :fa-icon="`fas ${settings.user.sfx ? 'fa-drum' : 'fa-volume-mute'}`">Sound FX {{settings.user.sfx ? 'ON' : 'OFF'}}</std-button>
        </span>
      </div>
      <div class="webhook-settings mb-3">
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
      <span class="d-flex justify-content-center mb-3">
        <a href="/users/sign_out" data-method="delete">
          <std-button @click.native="$root.$emit('close-modal')" fa-icon="fas fa-sign-out-alt" small>Sign out</std-button>
        </a>
        <!-- <std-button @click.native="$root.$emit('close-modal')" fa-icon="fas fa-times-circle" small>Leave room</std-button> -->
      </span>
    </div>
    <div class="ui-controls-bottom">
      <std-button @click.native="$root.$emit('close-modal')" fa-icon="fas fa-times-circle" >Cancel</std-button>
      <std-button @click.native="updateSettings" fa-icon="fas fa-save" large >Save</std-button>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    settings: Object,
    moderator: Boolean,
  },
  data() {
    return {
      tooltipText: "Copy to clipboard",
      displayName: this.settings.user.name,
      codewarsLangs: {
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
          music: this.settings.user.music,
        }
      }
    },
  },
  methods: {
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