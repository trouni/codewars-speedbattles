<template>
  <div>
    <div class="mt-3 mb-5">
      <h2>Room settings</h2>
      <small>You are a moderator for this war room.</small>
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
        <h5>Audio</h5>
      </div>
      <small>Activate/deactivate music and sound effects/announcements.</small>
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
        room: {
          name: this.roomName,
          voice_chat_url: this.settings.room.voice_chat_url,
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