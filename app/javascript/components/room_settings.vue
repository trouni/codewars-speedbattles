<template>
  <div>
    <div class="mt-3">
      <h3>Room settings</h3>
      <!-- <small>You are moderator for this war room.</small> -->
    </div>
    <div class="form-group mt-3 mb-5">
      <!-- <h5 class="no-wrap">Room name</h5> -->
      <input
        @keydown.enter="updateSettings"
        type="text"
        :placeholder="settings.user.username"
        class="form-control"
        v-model="roomName"
        maxlength="50"
      />
    </div>
    <div class="mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Classification level</h5>
        <select v-model="classification" class="flex-grow-1 ml-3">
          <option v-for="(classification, value) in classificationLevels" :value="classification" :key="value">{{ value }}</option>
        </select>
      </div>
      <small>Choose who can see the challenge's name before a battle. The challenge's name is revealed to everyone during the countdown.</small>
    </div>
    <div class="form-group mb-5">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Voice & music</h5>
        <std-button
            @click.native="$root.$emit('toggle-room-sound')"
            :fa-icon="`fas ${settings.room.sound ? 'fa-volume-up' : 'fa-volume-down'}`"
          >{{settings.room.sound ? 'Everyone' : 'Moderator only'}}</std-button>
      </div>
      <small><em>Moderator only</em> disables music and announcements for all other players. Useful when all players are in the same room.</small>
    </div>
    <div class="form-group mb-5">
      <h5 class="no-wrap">Voice chat url</h5>
      <small>Invitation link for video/voice call (Zoom/Slack/etc.)</small>
      <input
        @keydown.enter="updateSettings"
        type="text"
        class="form-control mt-2"
        v-model="voiceChatUrl"
      />
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
      classification: this.settings.room.classification,
      classificationLevels: {
        'TOP SECRET (no one)': 'TOP SECRET',
        'CONFIDENTIAL (moderator)': 'CONFIDENTIAL',
        'UNCLASSIFIED (everyone)': 'UNCLASSIFIED'
      }
    }
  },
  computed: {
    updatedSettings() {
      return {
        room: {
          name: this.roomName,
          voice_chat_url: this.voiceChatUrl,
          sound: this.settings.room.sound,
          classification: this.classification,
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