<template>
  <div
    id="super-container"
    :class="[
      viewMode,
      roomStatus,
      {
        'unfocused': unfocused || !wsConnected,
        'disconnected': !wsConnected,
        'low-res': settings.user.low_res_theme,
      }
    ]">
    <span :class="['app-bg', {'initializing': initializing}]"/>

    <navbar v-if="currentUserId" :loading="settingsLoading || !wsConnected" />
    <modal
      v-if="focus === 'modal' && userSettingsInitialized"
      id="room-modal"
      title="SYS://Settings">
      <template>
        <user-settings :settings="settings"/>
      </template>
      <template v-slot:secondary v-if="currentUserIsModerator">
        <room-settings :settings="settings"/>
      </template>
    </modal>

    <spinner v-if="!focus && (initializing || !wsConnected)" class="animated fadeIn">
      {{ wsConnected ? 'LOADING' : 'CONNECTING' }}
      <p v-if="longDisconnection" class="absolute-h-center mt-5 animated fadeIn">
        <small>Taking too long?</small>
        <std-button small @click.native="reloadBrowser" class="no-wrap">Refresh the page</std-button>
      </p>
    </spinner>

    <slot v-bind:settings="settings">
    </slot>
  </div>
</template>

<script>
import Vue from 'vue/dist/vue.esm'
import debounce from "lodash/debounce";
import kebabCase from "lodash/kebabCase";
import RoomSettings from "./components/settings/room_settings.vue";
import UserSettings from "./components/settings/user_settings.vue";

export default {
  components: {
    RoomSettings,
    UserSettings
  },
  props: {
    roomInit: {
      type: Object,
      default: function() {
        return { id: null }
      }
    },
    currentUserId: {
      type: Number,
      default: null
    },
  },
  data() {
    return {
      ambianceMusic: new Audio(),
      announcement: {
        content: null,
        defaultContent: null,
        status: "normal"
      },
      battle: {},
      battleInitialized: false,
      battleLoading: false,
      challengeInput: "",
      chat: {
        authors: [],
        messages: []
      },
      clockInterval: null,
      controlsType: "",
      countdownDuration: 15,
      countdown: 0,
      countdownMsg: null,
      countdownEndMsg: null,
      focus: new URL(window.location.href).searchParams.get("settings") === 'show' ? 'modal' : null,
      longDisconnection: false,
      // leaderboard: {},
      messagesInitialized: false,
      modalContent: 'user',
      openedCodewars: false,
      room: this.roomInit,
      roomPlayers: [],
      roomPlayersLoading: false,
      roomSettingsInitialized: false,
      roomSettingsLoading: true,
      settings: {
        room: {
          sound: true
        },
        user: {
          sfx: true
        },
      },
      sounds: {
        ambiance: {
          battles: [new Audio("../../audio/bensound-epic-med.mp3"), new Audio("../../audio/overpowered-med.mp3"), new Audio('../../audio/infinity-star-med.mp3')],
          drums: new Audio('../../audio/bg-drums.mp3')
        },
        fx: {
          click: new Audio("../../audio/select.mp3"),
          countdown: new Audio("../../audio/countdown.mp3"),
          // https://audiojungle.net/item/counting-countdown-timer/21635290
          countdownTick: new Audio('../../audio/countdown-tick.wav'),
          countdownZero: new Audio('../../audio/battlecruiser.mp3'),
          drums: new Audio("../../audio/drums.mp3"),
          message: new Audio("../../audio/hover.mp3"),
          interface: new Audio("../../audio/interface.mp3"),
          mouseenter: new Audio("../../audio/beep.mp3"),
          mouseover: new Audio("../../audio/beep.mp3"),
          sword: new Audio("../../audio/sword.mp3")
        },
        musicOn: true,
        soundFxOn: true,
        volumeAmbiance: 0.5,
        volumeBackgroundAmbiance: 0.2
      },
      timer: null,
      users: [],
      userSettingsInitialized: false,
      userSettingsLoading: true,
      usersInitialized: false,
      viewMode: new URL(window.location.href).searchParams.get("view"),
      wsConnected: false,
      reconnectInterval: null
    };
  },
  created() {
  },
  watch: {
    sounds: {
      handler: function() {
        this.ambianceMusic.volume = this.musicON ? this.sounds.volumeAmbiance : 0;
      },
      deep: true
    },
  },
  computed: {
    roomId() {
      return this.roomInit ? this.roomInit.id : null
    },
    roomName() {
      return this.settings.room.name || ''
    },
    settingsLoading() {
      return this.userSettingsLoading
    },
    someDataLoaded() {
      return true
    },
    initializing() {
      return this.currentUserId && !this.userSettingsInitialized
    },
    unfocused() {
      return this.focus !== null || !this.wsConnected
    },
    allDataLoaded() {
      return (
        this.userSettingsInitialized && this.currentUserId
      );
    },
    seekAttention() {
      if (this.battleStage === 4) {
        return ["animated pulse seek-attention"];
      } else {
        return null;
      }
    },
    announcerWindow() {
      let status = this.announcement.status || "normal";
      let content = this.announcement.content || this.announcement.defaultContent;

      return {
        status: status,
        content: content
      };
    },
    challengeUrl() {
      if (this.battle.challenge) {
        const language = this.battle.challenge.language || "ruby";
        return `${this.battle.challenge.url}/train/${language}`;
      }
    },
    currentUser() {
      if (!this.usersInitialized) return

      const currentUserIndex = this.users.findIndex(
        e => e.id === this.currentUserId
      );

      if (currentUserIndex !== -1) return this.users[currentUserIndex]
    },
    currentUserIsModerator() {
      return false
    },
    invitedUsers() {
      if (this.battleStage === 0) { return [] }

      return this.users.filter(user => user.invite_status === 'invited')
    },
    confirmedUsers() {
      if (!this.users) {
        return [];
      } else {
        return this.users.filter(
          user => user.invite_status == "confirmed"
        );
      }
    },
    allConfirmed() {
      return this.battleStage === 2 && this.invitedUsers.length === 0;
    },
    roomStatus() {
      // STATUSES
      if (this.battleStage >= 4) {
        return "war";
      } else if (this.battleStage === 3) {
        return this.battleJoinable ? "ready-for-battle" : "countdown";
      } else if (this.battleStage === 2) {
        return "battle-confirmed";
      } else if (this.battleStage === 1) {
        return "battle-loaded";
      } else {
        return "peace";
      }
    },
    battleStage() {
      return this.battle.stage || 0
    },
    battleLoaded() {
      if (!this.battle.id) return false;

      return !this.battle.start_time && !this.battle.end_time;
    },
    readyToStart() {
      if (!this.battle.id) return false;

      return (
        this.battleStage < 3 &&
        this.confirmedUsers.length > 1
      );
    },
    readyForBattle() {
      if (!this.battle.id || !this.currentUser) return false;

      if (this.currentUserIsModerator) {
        return this.allConfirmed
      } else {
        return this.battleStage < 3 && this.currentUser.invite_status === "confirmed"
      }
    },
    battleCountdown() {
      if (!this.battle.id) return false;

      return (
        !!this.battle.start_time &&
        !this.battle.end_time &&
        this.countdown !== 0
      );
    },
    battleJoinable() {
      if (!this.battle.id) return false;

      return this.battleLoaded && (this.battleStage < 3 || (this.battleStage === 3 && this.countdown > 10));
    },
    battleOngoing() {
      if (!this.battle.id) return false;

      return (
        !!this.battle.start_time &&
        !this.battle.end_time &&
        this.countdown === 0
      );
    },
    battleOver() {
      if (!this.battle.id) return true;

      return !!this.battle.end_time;
    },
    eventMode() {
      return !this.settings.room.sound
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
        room_id: this.roomId,
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
    announce(message) {
      if (message.content) {
        this.announcement = {
          status: message.status || "normal",
          content: message.content
        };
      }
      if (message.chat && this.currentUserIsModerator && !this.viewMode) {
        const chatMessage =
          message.chat === true ? message.content : message.chat;
        this.sendChatMessage(chatMessage, true);
      }
    },
    sendChatMessage(message, announcement = false) {
      this.sendCable("create_message", {
        message: message,
        announcement: announcement
      });
      this.input = "";
    },
    speak(message, options = null) {
      options = options || {}
      if (this.voiceON) {
        if (options.interrupt) speechSynthesis.cancel();
        const msg = new SpeechSynthesisUtterance(message);
        const voices = speechSynthesis.getVoices();
        const voiceURI = options.voiceURI || "Google US English";
        const soundFX = options.fx
        const fxVolume = options.fxVolume
        const fxPlayAt = options.fxPlayAt || 'asap'
        msg.voice =
          voices[voices.findIndex(e => e.voiceURI === voiceURI)];
        // msg.rate = 1.1;
        // msg.pitch = 0.85;
        msg.onstart = () => {
          this.setBackgroundVolume()
          if (fxPlayAt === 'start') this.playSoundFx(soundFX, fxVolume);
        };
        msg.onend = () => {
          this.resetAmbianceVolume()
          if (fxPlayAt === 'end') this.playSoundFx(soundFX, fxVolume);
        };
        if (fxPlayAt === 'asap') this.playSoundFx(soundFX, fxVolume);
        if (message) speechSynthesis.speak(msg);
      }
    },
    setBackgroundVolume() {
      this.ambianceMusic.volume = Math.min(
        this.ambianceMusic.volume,
        this.sounds.volumeBackgroundAmbiance
      );
    },
    resetAmbianceVolume() {
      this.ambianceMusic.volume = this.musicON ? this.sounds.volumeAmbiance : 0;
    },
    startAmbiance(track = null) {
      if (track) {
        this.ambianceMusic = this.sounds.ambiance[track]
      } else {
        this.ambianceMusic = this.sounds.ambiance.battles[
          Math.floor(Math.random() * this.sounds.ambiance.battles.length)
        ];
      }
      // this.ambianceMusic.loop = true
      this.ambianceMusic.volume = this.musicON ? this.sounds.volumeAmbiance : 0;
      this.ambianceMusic.onended = () => {
        this.startAmbiance(track);
      };
      if (this.ambianceMusic.paused) this.ambianceMusic.play();
    },
    pauseAmbiance() {
      this.ambianceMusic.pause();
    },
    resumeAmbiance() {
      this.ambianceMusic.play();
    },
    stopAmbiance() {
      this.ambianceMusic.pause();
      this.ambianceMusic.currentTime = 0;
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
    playVoiceFx(fxName, volume = 1) {
      // volume = volume || 1
      const soundFX = this.sounds.fx[fxName]
      if (!soundFX) return

      soundFX.pause();
      soundFX.currentTime = 0;
      soundFX.volume = volume;
      soundFX.onended = () => {
        this.resetAmbianceVolume()
      };
      this.setBackgroundVolume()
      if (this.voiceON) soundFX.play();
    },
    parseDates(element, dateFields) {
      dateFields.forEach(field => {
        if (element[field]) {
        let timestamp = String(element[field])
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
        window.longDisconnectionTimeout = setTimeout(_ => this.longDisconnection = true, 8000)
      },
      received(data) {
        if (data.roomId !== this.roomId && data.userId !== this.currentUserId) return;

        switch (data.subchannel) {
          case "action":
            switch (data.payload.action) {
              case "update-countdown":
                this.countdown = data.payload.data.countdown;
                break;

              case "voice-announce":
                this.speak(data.payload.message, data.payload.options);
                break;

              case "open-codewars":
                if (this.currentUser.invite_status === "confirmed" && !this.viewMode) this.openCodewars();
                break;

              default:
                if (this.currentUserIsModerator)
                  console.log(
                    "Received data, without matching subchannel:",
                    data
                  );
            }
            break;

          case "settings":
            switch (data.payload.action) {
              case "user":
                Vue.set(this.settings, 'user', data.payload.settings)
                // this.settings.user = data.payload.settings
                this.userSettingsInitialized = true
                this.userSettingsLoading = false
                break;

              case "room":
                this.settings.room = data.payload.settings;
                this.announcement.defaultContent = `Welcome to ${this.settings.room.name}`
                this.refreshCountdown()
                this.roomSettingsInitialized = true
                this.roomSettingsLoading = false
                break;
            }
            break;  

          default:
            if (this.currentUserIsModerator)
              console.log("Received data, without matching subchannel:", data);
        }
      },
      onerror() {
        console.log("Error");
      },
      disconnected() {
        console.warn('Disconnected from cable.')
        this.wsConnected = false
        window.longDisconnectionTimeout = setTimeout(_ => this.longDisconnection = true, 15000)
      }
    }
  },
  mounted() {
    if (!this.currentUserId) {
      // If user is not logged in
      this.wsConnected = true
      this.userSettingsInitialized = true
      this.userSettingsLoading = false
      return
    }

    speechSynthesis.cancel();

    this.subscribeToCable();

    this.$root.$on("announce", message => this.announce(message));
    this.$root.$on("send-chat-message", message =>
      this.sendChatMessage(message)
    );
    this.$root.$on(
      "change-volume-ambiance",
      volume => (this.sounds.volumeAmbiance = volume)
    );
    this.$root.$on("toggle-settings", this.toggleSettings);
    this.$root.$on("update-settings", settings => this.updateSettings(settings));
    this.$root.$on("close-modal", this.closeModal);
    this.$root.$on("get-katas-count", kataOptions => this.getKatasCount(kataOptions));
    this.$root.$on("create-battle", battleInfo => this.createBattle(battleInfo));
    this.$root.$on("create-random-battle", this.createRandomBattle);
    this.$root.$on("show-offline-players", this.getRoomPlayers);
    this.$root.$on("delete-battle", this.deleteBattle);
    this.$root.$on("fetch-challenges", (userId = null) => this.fetchChallenges(userId));
    this.$root.$on("invite-user", userId => this.invitation("invite", userId));
    this.$root.$on("uninvite-user", userId =>
      this.invitation("uninvite", userId)
    );
    this.$root.$on("invite-all", () => this.invitation("all"));
    this.$root.$on("invite-survivors", () => this.invitation("survivors"));
    this.$root.$on("confirm-invite", userId =>
      this.invitation("confirm", userId)
    );
    this.$root.$on("initialize-battle", this.initializeBattle);
    this.$root.$on("start-countdown", this.startCountdown);
    this.$root.$on("end-battle", this.userEndsBattle);
    this.$root.$on("edit-time-limit", timeLimit => this.editTimeLimit(timeLimit));
    this.$root.$on("speak", message => this.speak(message));
    this.$root.$on("play-fx", sound => this.playSoundFx(sound));
    this.$root.$on("play-ambiance", track => this.startAmbiance(track));
    this.$root.$on("toggle-voice", this.toggleVoice);
    this.$root.$on("toggle-music", this.toggleMusic);
    this.$root.$on("toggle-sound-fx", () => this.settings.user.sfx = !this.settings.user.sfx);
    this.$root.$on("toggle-room-sound", () => this.settings.room.sound = !this.settings.room.sound);
    this.$root.$on("toggle-low-res", () => this.settings.user.low_res_theme = !this.settings.user.low_res_theme);
  }
};
</script>

<style>

</style>