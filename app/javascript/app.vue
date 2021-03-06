<template>
  <div
    id="super-container"
    :class="[
      roomStatus,
      {
        'unfocused': unfocused,
        'disconnected': !wsConnected,
        'low-res': settings.user.low_res_theme,
      }
    ]">
    <span :class="['app-bg', {'initializing': initializing}]"/>

    <navbar v-if="!initializing" :loading="settingsLoading || !wsConnected" />

    <modal
      v-if="focus === 'modal' && !initializing"
      id="room-modal"
      title="SYS://Settings">
      <template>
        <user-settings :settings="settings" :moderator="currentUserIsModerator"/>
      </template>
      <template v-slot:secondary v-if="currentUserIsModerator">
        <room-settings :settings="settings"/>
      </template>
      <template v-slot:secondary v-else-if="!signedIn">
        <div class="my-4 d-contents">
          <h5 class="highlight-red mx-auto mb-4 font-weight-bold">Join the battlefield...</h5>
          <login-form />
          <div class="d-flex justify-content-center align-items-center mt-3">
            <p class="small mr-3">Need an account?</p>
            <a href="/users/sign_up">
              <std-button fa-icon="fas fa-star-of-life" small>Sign up</std-button>
            </a>
          </div>
        </div>
      </template>
    </modal>

    <spinner v-if="initializing || (room.id && !wsConnected)" class="animated fadeIn">
      <div v-if="disconnected">
        DISCONNECTED
        <p class="absolute-h-center mt-5 animated fadeIn delay-2s">
          <small class="no-wrap text-center">You have been disconnected from this room.</small>
          <std-button small @click.native="reloadBrowser" class="no-wrap m-auto">Refresh the page</std-button>
        </p>
      </div>
      <div v-else>
        {{ wsConnected ? 'LOADING' : 'CONNECTING' }}
        <p v-if="!wsConnected" class="absolute-h-center mt-5 animated fadeIn delay-10s">
          <small class="no-wrap text-center">Taking too long?</small>
          <std-button small @click.native="reloadBrowser" class="no-wrap m-auto">Refresh the page</std-button>
        </p>
      </div>
    </spinner>

    <slot
      v-if="!initializing"
      :settings="settings"
      :signed-in="signedIn"
      :announcer-window="announcerWindow"
      :battle-joinable="battleJoinable"
      :battle-loading="battleLoading"
      :battle-stage="battleStage"
      :battle="battle"
      :chat="chat"
      :countdown="countdown"
      :current-user-is-moderator="currentUserIsModerator"
      :current-user="currentUser"
      :focus="focus"
      :initializing="initializing"
      :messages-loading="messagesLoading"
      :ready-to-start="readyToStart"
      :room-name="roomName"
      :room-players-loading="roomPlayersLoading"
      :room-players="roomPlayers"
      :room-settings-initialized="roomSettingsInitialized"
      :room="room"
      :users-loading="usersLoading"
      :users="users"
      >
    </slot>
  </div>
</template>

<script>
import Vue from 'vue/dist/vue.esm'
import debounce from "lodash/debounce";
import kebabCase from "lodash/kebabCase";
import RoomSettings from "./components/settings/room_settings";
import UserSettings from "./components/settings/user_settings";
import LoginForm from "./components/sign_up/login_form";

export default {
  components: {
    RoomSettings,
    UserSettings,
    LoginForm
  },
  props: {
    room: {
      type: Object,
      default: function() {
        return { id: null }
      }
    },
    currentUserId: {
      type: Number,
      default: 0
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
      battleLoading: true,
      challengeInput: "",
      chat: {
        authors: [],
        messages: []
      },
      clockInterval: null,
      countdownDuration: 15,
      countdown: 0,
      countdownMsg: null,
      countdownEndMsg: null,
      disconnected: false,
      focus: new URL(window.location.href).searchParams.get("settings") === 'show' ? 'modal' : null,
      fontsLoaded: false,
      messagesLoading: true,
      modalContent: 'user',
      openedCodewars: false,
      roomPlayers: [],
      roomPlayersLoading: false,
      roomSettingsInitialized: false,
      roomSettingsLoading: true,
      settings: {
        room: {
          sound: true
        },
        user: {
          connected_webhook: true
        },
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
      timer: null,
      users: [],
      userSettingsInitialized: false,
      userSettingsLoading: true,
      usersLoading: true,
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
    battleStage: {
      handler: function(battleStage, oldVal) {
        if (this.battleStage === 4) {
          this.loadAmbiance({ play: true })
          if (!this.battle.time_limit) this.startClock()
        } else {
          this.stopAmbiance()
        }

        if (this.battleStage === 3) {
        } else if (this.battleStage === 2) {
        } else if (this.battleStage === 1) {
          this.announce({ content: "Waiting for players to join..." })
        } else if (this.battleStage === 0) {
          this.stopAmbiance()
          this.openedCodewars = false;
        }
      },
      immediate: true
    },
    countdown: {
      handler: function(countdown) {
        if (countdown >= 0) {
          const clockTime = this.battleStage !== 3 ? this.formatDuration(countdown) : countdown
          this.announcement.status = "warning";
          this.announcement.content = `<p><small class='m-0'>${this.countdownMsg}</small></p><span class="timer highlight">${clockTime}</span>`;
        } else if (this.countdownEndMsg) {
          this.announcement.content = this.countdownEndMsg;
          this.countdownEndMsg = null;
        } else {
          this.announcement.content = null
        }
      }
    },
  },
  computed: {
    roomName() {
      return this.settings.room.name || ''
    },
    settingsLoading() {
      return this.userSettingsLoading || this.room.id && this.roomSettingsLoading
    },
    initializing() {
      return !(
        this.fontsLoaded &&
        !this.disconnected &&
        (
          !this.room.id || (
            this.userSettingsInitialized &&
            this.roomSettingsInitialized
          )
        )
      )
    },
    unfocused() {
      return this.focus !== null || (!this.wsConnected && this.room.id)
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
        const language = this.settings.user.hljs_lang || this.battle.challenge.language || "ruby";
        return `${this.battle.challenge.url}/train/${language}`;
      }
    },
    signedIn() {
      return this.currentUserId !== 0
    },
    currentUser() {
      const spectator = { id: 0, invite_status: 'spectator' }

      const currentUserIndex = this.users.findIndex(
        e => e.id === this.currentUserId
      );

      return currentUserIndex !== -1 ? this.users[currentUserIndex] : spectator
    },
    currentUserIsModerator() {
      return this.currentUserId === this.room.moderator_id;
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
        this.confirmedUsers.length >= this.battle.min_players
      );
    },
    battleJoinable() {
      if (!this.battle.id) return false;

      return this.battleLoaded && (this.battleStage < 3 || (this.battleStage === 3 && this.countdown > 10));
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
        room_id: this.room.id,
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
    disconnectRoom() {
      this.disconnected = true
      this.wsConnected = false
    },
    openModal() {
      this.focus = 'modal'
    },
    closeModal() {
      if (this.focus === 'modal' || this.focus === 'webhook') {
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
      if (message.chat && this.currentUserIsModerator) {
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
        msg.rate = 0.9;
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
    // =============
    //     BATTLE
    // =============
    getKatasCount(kataOptions) {
      this.sendCable("available_katas_count", { kata: kataOptions });
    },
    createBattle(battleInfo) {
      this.battleLoading = true
      this.battle = {}
      const challengeIdSlug = this.parseChallengeInput(battleInfo.challenge)
        .challengeIdSlug;
      this.sendCable("create_battle", {
        challenge_id: challengeIdSlug,
        time_limit: battleInfo.timeLimit,
        auto_invite: battleInfo.autoInvite,
      });
    },
    createRandomBattle(battleOptions) {
      this.battleLoading = true
      this.battle = {}
      this.sendCable('create_random_battle', battleOptions)
    },
    deleteBattle() {
      this.battleLoading = true
      if (this.battleLoaded) this.sendCable("delete_battle", { battle_id: this.battle.id });
    },
    parseChallengeInput(input) {
      const urlRegex = /^(https:\/\/)?www\.codewars\.com\/kata\/(?<challengeIdSlug>.+?)\/?(train\/(?<language>.+))?$/;
      const matchData = input.match(urlRegex);
      if (matchData) {
        return {
          challengeIdSlug: matchData.groups.challengeIdSlug,
          language: matchData.groups.language
        };
      } else {
        return {
          challengeIdSlug: kebabCase(input),
          language: null
        };
      }
    },
    initializeBattle() {
      if (this.battleStage < 3) {
        this.sendCable("update_battle", {
          battle_action: "start",
          battle_id: this.battle.id,
          countdown: this.countdownDuration,
        });
      }
    },
    userEndsBattle() {
      if (this.currentUserIsModerator && this.battleStage > 3)
        this.sendCable("update_battle", {
          battle_action: 'ended-by-user',
          battle_id: this.battle.id,
        });
    },
    fetchChallenges(userId) {
      this.sendCable("fetch_user_challenges", {
        user_id: userId ? userId : this.currentUserId,
        battle_id: this.battle.id
      });
    },
    getRoomPlayers(userId) {
      this.roomPlayersLoading = true
      this.sendCable("get_room_players");
    },
    openCodewars(force = false) {
      if ((this.openedCodewars && !force) || this.battleStage < 4) return;

      this.openedCodewars = true;
      window.open(this.challengeUrl);
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
    loadAmbiance(args = { track: null, play: false }) {
      if (args.track) {
        this.ambianceMusic = this.sounds.ambiance[args.track]
      } else {
        this.ambianceMusic = this.sounds.ambiance.battles[
          Math.floor(Math.random() * this.sounds.ambiance.battles.length)
        ];
      }
      // this.ambianceMusic.loop = true
      this.ambianceMusic.volume = this.musicON ? this.sounds.volumeAmbiance : 0;
      this.ambianceMusic.onended = () => {
        this.loadAmbiance({ track: args.track, play: true });
      };
      this.ambianceMusic.pause();
      if (args.play) this.ambianceMusic.play();
    },
    pauseAmbiance() {
      this.ambianceMusic.pause();
    },
    resumeAmbiance() {
      this.ambianceMusic.play();
    },
    stopAmbiance() {
      this.loadAmbiance({ play: false })
      // this.ambianceMusic.pause();
      // this.ambianceMusic.currentTime = 0;
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
    // ==========
    // COUNTDOWN
    // ==========
    refreshCountdown() {
      if (this.settings.room.next_event && this.settings.room.next_event.timer >= 0) {
        this.countdown = Math.round(this.settings.room.next_event.timer);
        switch (this.settings.room.next_event.type) {
          case 'start-battle':
            this.countdownMsg = 'Battle starting in...';
            // this.countdownEndMsg = 'Starting battle...';
            this.startCountdown(this.countdown, this.startBattleCountdown);
            break;

          case 'next-battle':
            this.countdownMsg = 'Loading next battle in...';
            // this.countdownEndMsg = 'Waiting for players to join...';
            this.startCountdown(this.countdown);
            break;

          case 'end-battle':
            this.countdownMsg = '';
            this.countdownEndMsg = 'The battle is over.';
            this.startCountdown(this.countdown, this.battleClockCountdown);
            break;

          default:
            break;
        }
      }
    },
    forceBattleStart() {
      // Assuming that the battle started successfully before the server broadcasts the new battle
      Vue.set(this.battle, 'stage', 4)
      Vue.set(this.battle, 'start_time', new Date())
      if (this.battle.time_limit) {
        this.countdown = this.battle.time_limit
        this.countdownMsg = null;
      } else {
        this.startClock()
      }
    },
    startBattleCountdown() {
      if (this.countdown < 0) {
        if (this.currentUser.invite_status === "confirmed") this.openCodewars();
        if (!this.voiceON) this.playSoundFx('countdownZero')
        this.forceBattleStart()
      } else {
        if (this.countdown === 10) this.playVoiceFx("countdown")
        if (this.countdown < 60) this.playSoundFx('countdownTick')
      }
    },
    battleClockCountdown() {
      const timeRemaining = this.countdown;
      if (timeRemaining <= 0) {
        this.stopAmbiance()
        if (!this.voiceON && timeRemaining === 0) this.playSoundFx('countdownZero')
        clearInterval(this.clockInterval);
      } else if (timeRemaining <= 10) {
        if (timeRemaining === 10) this.playVoiceFx("countdown")
        if (!this.voiceON) this.playSoundFx('countdownTick')
      } else if (timeRemaining === 61) {
        this.speak("WARNING! 1min remaining!", { interrupt: true });
      } else if (timeRemaining === 121) {
        this.speak("WARNING! 2min remaining!", { interrupt: true });
      } else if (timeRemaining === 301) {
        this.speak("WARNING! 5min remaining!", { interrupt: true });
      }
    },
    startCountdown(countdown = null, callback = _ => {}) {
      if (countdown) this.countdown = countdown;
      if (this.countdown <= 0) return;
      
      clearInterval(this.timer);
      // Last iteration when countdown == -1
      this.timer = setInterval(() => {
        callback();
        if (this.countdown < 0) {
          clearInterval(this.timer)
        };
        this.countdown -= 1;
      }, 1000);
    },
    startClock() {
      clearInterval(this.clockInterval);
      this.clockInterval = setInterval(() => {
        if (this.countdown > 0) {
          clearInterval(this.clockInterval);
        } else if (this.battleStage >= 3) {
          const clockTime = this.timeSpentInSeconds();
          this.announce({
            content: `<p class='highlight'><small>TIME ELAPSED</small></p><span class="timer highlight no-limit">${this.formatDuration(clockTime)}</span>`
          });
        } else {
          clearInterval(this.clockInterval);
        }
      })
    },
    timeSpentInSeconds() {
      return (Date.now() - Date.parse(this.battle.start_time)) / 1000;
    },
    timeRemainingInSeconds() {
      return Math.ceil(this.battle.time_limit - this.timeSpentInSeconds());
    },
    formatDuration(durationInSeconds) {
      if (durationInSeconds < 0) durationInSeconds = 0;
      const hours = Math.floor(durationInSeconds / 60 / 60);
      const minutes = Math.floor(durationInSeconds / 60) % 60;
      const seconds = Math.floor(
        durationInSeconds - hours * 60 * 60 - minutes * 60
      );
      return `${hours > 0 ? `${String(hours).padStart(2, "0")}:` : ""}${String(
        minutes
      ).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
    },
    formatDurationForSpeech(durationInSeconds) {
      if (durationInSeconds < 0) durationInSeconds = 0;
      const hours = Math.floor(durationInSeconds / 60 / 60);
      const minutes = Math.floor(durationInSeconds / 60) % 60;
      const seconds = Math.floor(
        durationInSeconds - hours * 60 * 60 - minutes * 60
      );
      return `${hours > 0 ? `${hours}hr ` : ""}${minutes}min${
        seconds > 0 ? ` ${seconds}sec` : ""
      }`;
    },
    // =============
    //     USERS
    // =============
    pushToArray(array, element) {
      const result = { newElement: element };
      const elementIndex = array.findIndex(e => e.id === element.id);
      if (elementIndex === -1) {
        array.push(element);
      } else {
        // Vue cannot detect change in the array with array[index] = user
        result.oldElement = array[elementIndex];
        array.splice(elementIndex, 1, element);
      }
      return result;
    },
    pushToUsers(user) {
      const dateFields = ['last_fetched_at', 'joined_room_at', 'joined_battle_at', 'completed_at']
      // Parsing dates before pushing user into array
      user = this.parseDates(user, dateFields)
      if (this.users) this.pushToArray(this.users, user);
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
    removeFromArray(array, element) {
      const elementIndex = array.findIndex(e => e.id === element.id);
      if (elementIndex !== -1) {
        array.splice(elementIndex, 1);
        // if (this.currentUserIsModerator) console.info('Removed element:', element)
      }
    },
    removeFromUsers(user) {
      if (this.users) this.removeFromArray(this.users, user);
    },
    invitation(inviteAction, userId = null) {
      this.sendCable("invitation", {
        battle_id: this.battle.id,
        invite_action: inviteAction,
        user_id: userId
      });
    },
    editTimeLimit(timeLimit) {
      this.sendCable("update_battle", {
        battle_action: "update",
        battle_id: this.battle.id,
        countdown: this.countdownDuration,
        battle: { id: this.battle.id, time_limit: timeLimit * 60 }
      });
    }
  },
  channels: {
    RoomChannel: {
      connected() {
        console.info('Connected to cable.')
        this.wsConnected = true
        this.reconnectInterval = setInterval(this.checkConnection, 5000);
      },
      rejected() {
        console.warn('Connection to cable rejected.')
        this.wsConnected = false
      },
      received(data) {
        if (data.roomId !== this.room.id && data.userId !== this.currentUserId) return;

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
                if (this.currentUser.invite_status === "confirmed") this.openCodewars();
                break;

              default:
                if (this.currentUserIsModerator)
                  console.log(
                    "Received data, without matching subchannel:",
                    data
                  );
            }
            break;

          case "chat":
            switch (data.payload.action) {
              case "all":
                Vue.set(this.chat, 'messages', data.payload.messages);
                Vue.set(this.chat, 'authors', data.payload.authors);
                // if (this.currentUserIsModerator) console.info(`Refreshed all messages`)
                this.messagesLoading = false;
                break;

              default:
                this.pushToArray(this.chat.messages, data.payload)
                break;
            }
            break;

          case "logs":
            if (this.currentUserIsModerator) console.info("LOGS", data.payload);
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
                if (!this.settings.room.updated_at || data.payload.settings.updated_at >= this.settings.room.updated_at) {
                  Vue.set(this.settings, 'room', data.payload.settings)
                }
                // this.settings.room = data.payload.settings;
                this.announcement.defaultContent = `Welcome to ${this.settings.room.name}`
                this.refreshCountdown()
                this.roomSettingsInitialized = true
                this.roomSettingsLoading = false
                break;
            }
            break;  

          case "users":
            switch (data.payload.action) {
              case "add":
                this.pushToUsers(data.payload.user);
                break;

              case "all":
                data.payload.users.forEach(user => this.pushToUsers(user));
                this.usersLoading = false;
                break;

              case "remove":
                if (data.payload.user.id === this.currentUserId)
                  // Still need to figure out trigger to disconnect
                  // this.disconnectRoom()
                this.users = this.users.filter(
                  e => e.id !== data.payload.user.id
                );
                break;

              case "room-players":
                data.payload.users.forEach(user => this.pushToUsers(user));
                this.usersLoading = false;
                this.roomPlayersLoading = false;
                break;
            }
            break;

          case "battles":
            switch (data.payload.action) {
              case "active":
                this.battleLoading = false;
                if (data.payload.battle) {
                  const dateFields = ['start_time', 'end_time']
                  // Parsing dates before pushing user into array
                  this.battle = this.parseDates(data.payload.battle, dateFields)
                } else {
                  // When room has no battle history
                  this.battle = {}
                }
                break;

              case "katas-count":
                Vue.set(this.settings.room.katas, 'count', data.payload.count)
                break;

              default:
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
      }
    }
  },
  mounted() {
    document.fonts.ready.then(_ => this.fontsLoaded = true)

    speechSynthesis.cancel();

    this.subscribeToCable();
    
    if (!this.signedIn && new URLSearchParams(window.location.search).get('join') !== null) {
      setTimeout(_ => { this.focus = 'modal' }, 3000)
    }

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
    this.$root.$on("set-focus", (focus) => this.focus = focus);
    this.$root.$on("invite-survivors", () => this.invitation("survivors"));
    this.$root.$on("confirm-invite", userId =>
      this.invitation("confirm", userId)
    );
    this.$root.$on("open-codewars", this.openCodewars);
    this.$root.$on("initialize-battle", this.initializeBattle);
    this.$root.$on("start-countdown", this.startCountdown);
    this.$root.$on("end-battle", this.userEndsBattle);
    this.$root.$on("edit-time-limit", timeLimit => this.editTimeLimit(timeLimit));
    this.$root.$on("speak", (message, options) => this.speak(message, options));
    this.$root.$on("play-fx", sound => this.playSoundFx(sound));
    this.$root.$on("toggle-voice", this.toggleVoice);
    this.$root.$on("toggle-music", this.toggleMusic);
    this.$root.$on("toggle-sound-fx", () => this.settings.user.sfx = !this.settings.user.sfx);
    this.$root.$on("toggle-room-sound", () => this.settings.room.sound = !this.settings.room.sound);
    this.$root.$on("toggle-low-res", () => this.settings.user.low_res_theme = !this.settings.user.low_res_theme);
  }
};
</script>

<style lang="scss">
</style>