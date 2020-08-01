<template>
  <div>
    <div class="mt-3">
      <h3><strong class="highlight">Room settings</strong></h3>
      <!-- <small>You are moderator for this war room.</small> -->
    </div>
    <div class="form-group mt-3 my-4">
      <!-- <h5 class="no-wrap">Room name</h5> -->
      <input
        @keydown.enter="updateSettings"
        type="text"
        :placeholder="settings.room.name"
        class="form-control"
        v-model="roomName"
        maxlength="50"
      />
      <small>The name of the war room.</small>
    </div>
    <div class="my-4">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="m-0">Room language</h5>
        <select v-model="language" class="flex-grow-1 ml-3">
          <option v-for="(key, lang_name) in settings.room.codewars_langs" :value="lang_name" :key="key">{{ key }}</option>
        </select>
      </div>
      <small>Select a coding language for the room's challenges and default syntax highlighting.</small>
    </div>
    <!-- <div class="form-group my-4">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="no-wrap">Difficulty</h5>
      </div>
      <small>Default difficuly level when loading a random kata.</small>
      <div v-for="row in [0, 1]" class="d-flex justify-content-center mt-3" :key="row">
        <rank-hex
          v-for="rank in [-8 + 4 * row, -7 + 4 * row, -6 + 4 * row, -5 + 4 * row]"
          :rank="rank"
          :inactive="!rankActive(rank)"
          class="clickable mx-2"
          @click.native="toggleRank(rank)"
          :key="rank"
        />
      </div>
    </div> -->
    <div class="form-group my-4">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="no-wrap m-0">Classification level</h5>
        <select v-model="classification" class="flex-grow-1 ml-3">
          <option v-for="(classification, value) in classificationLevels" :value="classification" :key="value">{{ value }}</option>
        </select>
      </div>
      <small>Choose who can see the challenge's name before a battle. The challenge's name is revealed to everyone during the countdown.</small>
    </div>
    <div class="form-group my-4">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="no-wrap m-0">Voice & music</h5>
        <std-button
            @click.native="$root.$emit('toggle-room-sound')"
            :fa-icon="`fas ${settings.room.sound ? 'fa-volume-up' : 'fa-volume-down'}`"
          >{{settings.room.sound ? 'Everyone' : 'Moderator only'}}</std-button>
      </div>
      <small><em>Moderator only</em> disables music and announcements for all other players. Useful when all players are in the same room.</small>
    </div>
    <div class="form-group my-4">
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
import Vue from 'vue/dist/vue.esm'
import EventBus from '../../services/event_bus'
import includes from 'lodash/includes'
import sortBy from 'lodash/sortBy'

export default {
  name: 'room-settings',
  props: {
    settings: Object,
  },
  // watch: {
  //   settings: {
  //     handler(newSettings) {
  //       this.roomName = this.newSettings.room.name
  //       this.voiceChatUrl = this.newSettings.room.voice_chat_url
  //       this.roomSound = this.newSettings.room.sound
  //       this.classification = this.newSettings.room.classification
  //       this.language = this.newSettings.room.languages[0]
  //     },
  //     deep: true
  //   }
  // },
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
      },
      // ranks: Vue.util.extend([], this.settings.room.ranks),
      language: this.settings.room.languages[0],
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
          // ranks: sortBy(this.ranks),
          // Storing languages as array for future mutli-lang room support
          languages: [this.language],
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
    // rankActive(rank) {
    //   return includes(this.ranks, rank)
    // },
    // toggleRank(rank) {
    //   this.rankActive(rank) ? this.ranks.splice(this.ranks.indexOf(rank), 1) : this.ranks.push(rank)
    // }
  }
}
</script>

<style>

</style>