<template>
  <div>
    <div class="mt-3 mb-5">
      <h2>Room settings</h2>
      <small>You are moderator for this war room.</small>
    </div>
    <div class="form-group mb-5">
      <h5 class="no-wrap">Room name</h5>
      <input
        @keydown.enter="updateSettings"
        type="text"
        :placeholder="settings.user.username"
        class="form-control"
        v-model="roomName"
        maxlength="50"
      />
      <!-- <small>By default, your Codewars username will be shown.</small> -->
    </div>
    <div class="form-group mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Moderator audio only</h5>
        <std-button
            @click.native="$root.$emit('toggle-room-sound')"
            :class="{'toggled-off': settings.room.sound}"
            :fa-icon="`fas ${settings.room.sound ? 'fa-volume-up' : 'fa-volume-down'}`"
          >Event mode {{settings.room.sound ? 'OFF' : 'ON'}}</std-button>
      </div>
      <small>Disables music and announcements for everyone except the moderator. Useful when all players are in the same room.</small>
    </div>
    <div class="form-group mb-5">
      <h5 class="no-wrap">Voice chat url</h5>
      <input
        @keydown.enter="updateSettings"
        type="text"
        class="form-control"
        v-model="voiceChatUrl"
      />
      <small>Invitation link to join video/voice call (Zoom/Slack/etc.)</small>
    </div>
  </div>
</template>

<script>
import EventBus from '../services/event_bus'

export default {
  name: 'user-settings',
  props: {
    settings: Object,
  },
  data() {
    return {
      roomName: this.settings.room.name,
      voiceChatUrl: this.settings.room.voice_chat_url,
      roomSound: this.settings.room.sound,
    }
  },
  computed: {
    updatedSettings() {
      return {
        room: {
          name: this.roomName,
          voice_chat_url: this.voiceChatUrl,
          sound: this.settings.room.sound,
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