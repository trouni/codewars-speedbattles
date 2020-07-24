<template>
  <div
    id="super-container"
    :class="[
      {
        'unfocused': unfocused || !wsConnected,
        'disconnected': !wsConnected,
        'low-res': settings.user.low_res_theme,
      }
    ]">
    <span :class="['app-bg', {'initializing': initializing}]"/>

    <modal id="room-modal" title="SYS://Settings">
      <template>
        <user-settings :settings="settings"/>
      </template>
    </modal>
  </div>
</template>

<script>
import Vue from 'vue/dist/vue.esm'
import debounce from "lodash/debounce";
import kebabCase from "lodash/kebabCase";
import UserSettings from "settings/user_settings.vue";

export default {
  components: {
    UserSettings
  },
  props: {
    currentUserId: Number,
  },
  data() {
    return {
      focus: null,
      longDisconnection: false,
      modalContent: 'user',
      settings: {
        room: {},
        user: {},
      },
      sounds: {
        ambiance: {
          battles: [new Audio("../audio/bensound-epic-med.mp3"), new Audio("../audio/overpowered-med.mp3"), new Audio('../audio/infinity-star-med.mp3')],
          drums: new Audio('../audio/bg-drums.mp3')
        },
        fx: {
          click: new Audio("../audio/select.mp3"),
          countdown: new Audio("../audio/countdown.mp3"),
          // https://audiojungle.net/item/counting-countdown-timer/21635290
          countdownTick: new Audio('../audio/countdown-tick.wav'),
          countdownZero: new Audio('../audio/battlecruiser.mp3'),
          drums: new Audio("../audio/drums.mp3"),
          message: new Audio("../audio/hover.mp3"),
          interface: new Audio("../audio/interface.mp3"),
          mouseenter: new Audio("../audio/beep.mp3"),
          mouseover: new Audio("../audio/beep.mp3"),
          sword: new Audio("../audio/sword.mp3")
        },
        musicOn: true,
        soundFxOn: true,
        volumeAmbiance: 0.5,
        volumeBackgroundAmbiance: 0.2
      },
      wsConnected: false,
      reconnectInterval: null
    };
  },
  watch: {
    settings: {
      handler(settings, oldSettings) {
        
      },
      deep: true
    },
  },
  computed: {
    settingsLoading() {
      return this.userSettingsLoading || this.roomSettingsLoading
    },
    someDataLoaded() {
      return (
        this.usersInitialized ||
        this.battleInitialized ||
        this.messagesInitialized
      );
    },
    initializing() {
      return !(
        this.userSettingsInitialized &&
        this.roomSettingsInitialized &&
        this.usersInitialized &&
        this.battleInitialized &&
        this.messagesInitialized &&
        this.currentUser
      )
    },
    unfocused() {
      return this.focus !== null || !this.wsConnected
    },
    allDataLoaded() {
      return (
        this.userSettingsInitialized &&
        this.roomSettingsInitialized &&
        this.usersInitialized &&
        this.battleInitialized &&
        this.messagesInitialized &&
        this.currentUser
      );
    },
    voiceON() {
      return this.settings.user.voice && (!this.eventMode || this.currentUserIsModerator)
    },
    sfxON() {
      return this.settings.user.sfx
    },
    musicON() {
      return this.settings.user.music && (!this.eventMode || this.currentUserIsModerator)
    },
  },
  methods: {
    subscribeToCable() {
      this.$cable.subscribe({
        channel: "RoomChannel",
        user_id: this.currentUserId
      });
    },
    sendCable(action, data) {
      this.$cable.perform({
        channel: "RoomChannel",
        action: action,
        data: data
      });
    },
    debouncedSendCable: debounce((cable, action, data) => {
      cable.perform({
        channel: "RoomChannel",
        action: action,
        data: data
      });
    }, 1000),
    // =============
    //     ROOM
    // =============
    reloadBrowser() {
      location.reload()
    },
    openModal() {
      this.focus = 'modal'
    },
    closeModal() {
      if (this.focus === 'modal') {
        this.focus = null
      }
    },
    openSettings() {
      this.openModal()
    },
    toggleSettings() {
      this.focus === 'modal' ? this.closeModal() : this.openModal()
    },
    updateSettings(updatedSettings) {
      if (updatedSettings.user) {
        this.userSettingsLoading = true
        this.sendCable("update_user_settings", { user: updatedSettings.user });
      } else if (updatedSettings.room) {
        this.roomSettingsLoading = true
        this.sendCable("update_room_settings", { room: updatedSettings.room });
      }
    },
    checkConnection() {
      if (this.initializing) {
        console.info('Taking longer than usual, trying to resubscribe...')
        this.sendCable("subscribed")
      }
      else clearInterval(this.reconnectInterval)
    },
    stripHTML(html) {
      var doc = new DOMParser().parseFromString(html, "text/html");
      return doc.body.textContent || "";
    },
    toggleMusic() {
      this.settings.user.music = !this.settings.user.music;
      this.settings.user.music ? this.resumeAmbiance() : this.pauseAmbiance();
    },
    toggleVoice() {
      this.settings.user.voice = !this.settings.user.voice;
      if (!this.settings.user.voice) speechSynthesis.cancel();
    },
    playSoundFx(fxName, volume = 1) {
      // volume = volume || 1
      const soundFX = this.sounds.fx[fxName]
      if (!soundFX) return

      soundFX.pause();
      soundFX.currentTime = 0;
      soundFX.volume = volume;
      if (this.sfxON) soundFX.play();
    },
    // =============
    //     USERS
    // =============
    parseDates(element, dateFields) {
      dateFields.forEach(field => {
        let timestamp = element[field]
        if (timestamp) {
          // If UTC timezone info is missing, add it to the string before parsing
          if (!timestamp.match(/Z$/i)) timestamp += 'Z'
          element[field] = new Date(timestamp)
        }
      })
      return element
    },
  },
  channels: {
    RoomChannel: {
      connected() {
        this.wsConnected = true
        clearTimeout(window.longDisconnectionTimeout)
        this.longDisconnection = false
        this.reconnectInterval = setInterval(this.checkConnection, 2000);
      },
      rejected() {
        console.warn('Connection to cable rejected.')
        this.wsConnected = false
        this.subscribeToCable()
        window.longDisconnectionTimeout = setTimeout(_ => this.longDisconnection = true, 8000)
      },
      received(data) {
        if (data.userId !== this.currentUserId) return;

        if (data.subchannel === 'settings') {
          if (data.payload.action === 'user') {
            Vue.set(this.settings, 'user', data.payload.settings)
            // this.settings.user = data.payload.settings
            this.userSettingsInitialized = true
            this.userSettingsLoading = false
            break;
          }
        }
      },
      onerror() {
        console.log("Error");
      },
      disconnected() {
        console.warn('Disconnected from cable.')
        this.wsConnected = false
        this.subscribeToCable()
        window.longDisconnectionTimeout = setTimeout(_ => this.longDisconnection = true, 15000)
      }
    }
  },
  mounted() {
    this.subscribeToCable();

    this.$root.$on("open-user-settings", this.openSettings);
    this.$root.$on("toggle-settings", this.toggleSettings);
    this.$root.$on("update-settings", settings => this.updateSettings(settings));
    this.$root.$on("close-modal", this.closeModal);
    this.$root.$on("play-fx", sound => this.playSoundFx(sound));
    this.$root.$on("play-ambiance", track => this.startAmbiance(track));
    this.$root.$on("toggle-voice", this.toggleVoice);
    this.$root.$on("toggle-music", this.toggleMusic);
    this.$root.$on("toggle-sound-fx", () => this.settings.user.sfx = !this.settings.user.sfx);
    this.$root.$on("toggle-room-sound", () => this.settings.room.sound = !this.settings.room.sound);
  }
};
</script>

<style scoped>
</style>
