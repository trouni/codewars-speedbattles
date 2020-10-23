<template>
  <div>
    <div v-if="moderator" class="mt-3">
      <h3><strong class="highlight">Profile settings</strong></h3>
      <!-- <small>You are moderator for this war room.</small> -->
    </div>
    <div class="form-group mt-3 my-4" v-if="settings.user.signed_in">
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
    <div class="form-group my-4">
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
    <div class="form-group my-4" v-if="settings.user.signed_in">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Preferred coding language</h5>
        <select v-model="hljsLang" class="flex-grow-1 ml-3">
          <option value></option>
          <option v-for="(key, lang_name) in settings.room.codewars_langs" :value="lang_name" :key="key">{{ key }}</option>
        </select>
      </div>
      <small>Select a preferred language for challenges and code blocks in the chat.</small>
    </div>
    <div class="webhook-settings my-4" v-if="settings.user.signed_in">
      <webhook-instructions :settings="settings" />
    </div>
    <div class="form-group my-4">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Low-res Theme</h5>
        <std-button
          @click.native="$root.$emit('toggle-low-res')"
          :fa-icon="`fas ${lowRes ? 'fa-adjust' : 'fa-image'}`"
        >{{ lowRes ? 'LOW RES' : 'STANDARD' }}</std-button>
      </div>
      <small>Alternative theme that removes transparency and other effects for slower devices.</small>
    </div>
    <div class="form-group my-4" v-if="settings.user.signed_in || settings.room.id">
      <div class="d-flex justify-content-around">
        <a href="/users/sign_out" data-method="delete" v-if="settings.user.signed_in">
          <std-button @click.native="cancel" fa-icon="fas fa-sign-out-alt" small>Sign out</std-button>
        </a>
        <a href="/rooms/" v-if="settings.room.id">
          <std-button @click.native="cancel" fa-icon="fas fa-angle-double-left" small>Leave room</std-button>
        </a>
      </div>
    </div>
  </div>
</template>

<script>
import EventBus from '../../services/event_bus'
import WebhookInstructions from './webhook_instructions'

export default {
  name: 'user-settings',
  components: {
    WebhookInstructions
  },
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
      displayName: this.settings.user.name,
      hljsLang: this.settings.user.hljs_lang,
      lowRes: this.settings.user.low_res_theme,
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
  }
}
</script>

<style>

</style>