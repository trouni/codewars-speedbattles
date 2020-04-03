<template>
  <div id="super-container" :class="[viewMode, roomStatus, {'ready-for-battle': readyForBattle}, {'isolate-focus': isolateFocus}, { 'initializing': !allDataLoaded }]">
    <span class="app-bg"/>
    <navbar :room-id="room.id" :sounds="sounds" />
    <spinner v-if="!allDataLoaded" title="LOADING" />

    <div id="room" :class="{ moderator: currentUserIsModerator }">
      <widget id="room-announcer" class="grid-item" :header-title="`PWD://War_Room/${room.name}`" :focus="focus === 'announcer'">
        <div class="d-flex align-items-center justify-content-center h-100">
          <span
            :class="['announcer mt-3', 'text-center', announcerWindow.status]"
            v-html="announcerWindow.content"
          ></span>
        </div>
      </widget>
      <room-battle
        id="room-battle"
        class="grid-item"
        :roomStatus="roomStatus"
        :battle="battle"
        :users="users"
        :room="room"
        :countdown="countdown"
        :battle-status="battleStatus"
        :current-user="currentUser"
        :current-user-is-moderator="currentUserIsModerator"
        :view-mode="viewMode"
        :time-limit="timeLimit"
        :ready-to-start="readyToStart"
        :loading="!usersInitialized && !battleInitialized"
        :focus="focus === 'battle'"
      />
      <room-leaderboard
        class="grid-item"
        :users="users"
        :room="room"
        :battle="battle"
        :leaderboard="leaderboard"
        :room-players="roomPlayers"
        :current-user="currentUser"
        :current-user-is-moderator="currentUserIsModerator"
        :loading="!usersInitialized"
        :focus="focus === 'leaderboard'"
      />
      <room-chat
        class="grid-item"
        :messages="chat.messages"
        :authors="chat.authors"
        :current-user="currentUser"
        :loading="!messagesInitialized"
        :focus="focus === 'chat'"
      />
    </div>
    <modal v-if="focus === 'modal'" id="room-modal" :title="`SYS://Settings`" :show="focus === 'modal'">
      <settings :settings="settings" :moderator="currentUserIsModerator"/>
    </modal>
  </div>
</template>

<script>
import _ from "lodash";
import RoomControls from "../components/room_controls.vue";
import RoomChat from "../components/room_chat.vue";
import RoomLeaderboard from "../components/room_leaderboard.vue";
import RoomBattle from "../components/room_battle.vue";
import Settings from "../components/settings.vue";

export default {
  components: {
    RoomControls,
    RoomChat,
    RoomLeaderboard,
    RoomBattle,
    Settings,
  },
  props: {
    roomInit: Object,
    currentUserId: Number,
  },
  data() {
    return {
      settingsInitialized: false,
      usersInitialized: false,
      battleInitialized: true,
      messagesInitialized: false,
      roomPlayersInitialized: false,
      battleLoading: true,
      room: this.roomInit,
      users: [],
      roomPlayers: [],
      battle: {},
      leaderboard: {},
      chat: {
        messages: [],
        authors: []
      },
      challengeInput: "",
      controlsType: "",
      countdownDuration: 10,
      countdown: 0,
      settings: {
        user: {},
        room: { sound: this.roomInit.sound }
      },
      sounds: {
        musicOn: true,
        soundFxOn: true,
        volumeAmbiance: 0.5,
        volumeBackgroundAmbiance: 0.2,
        fx: {
          countdown: new Audio("../audio/countdown.mp3"),
          sword: new Audio("../audio/sword.mp3"),
          hover: new Audio("../audio/hover.mp3"),
          interface: new Audio("../audio/interface.mp3"),
          mouseover: new Audio("../audio/beep.mp3"),
          mouseenter: new Audio("../audio/beep.mp3"),
          click: new Audio("../audio/select.mp3"),
          drums: new Audio("../audio/drums.mp3"),
        },
        ambiance: {
          battles: [
            new Audio("../audio/bensound-epic-med.mp3"),
            new Audio("../audio/overpowered-med.mp3"),
            new Audio('../audio/infinity-star-med.mp3'),
          ],
          drums: new Audio('../audio/bg-drums.mp3'),
        },
      },
      ambianceMusic: new Audio(),
      announcement: {
        status: "normal",
        content: `Welcome to ${this.roomInit.name}`
      },
      viewMode: new URL(window.location.href).searchParams.get("view"),
      timeLimit: this.battle ? Math.round(this.battle.time_limit / 60) : 8,
      clockInterval: null,
      isolateFocus: false,
      focus: null,
      modalContent: 'user',
    };
  },
  created() {
    // this.pushToUsers(this.currentUser);
    // setTimeout(() => { this.someDataLoaded = true }, 500);
    this.$set(this.battle, "stage", this.battleStage);
    setTimeout(_ => this.checkCurrentUserConnection(), 5000);
  },
  watch: {
    battle: function() {
      this.timeLimit = this.battle ? Math.round(this.battle.time_limit / 60) : this.timeLimit;
    },
    sounds: {
      handler: function() {
        this.ambianceMusic.volume = this.musicON ? this.sounds.volumeAmbiance : 0;
      },
      deep: true
    },
    battleStage: function() {
      if (this.battleStage === 4) this.startAmbiance();
    }
  },
  computed: {
    // challengeInput() {
    //   if (this.battle.stage > 0 && this.battle.challenge) {
    //     return this.battle.challenge.name
    //   } else {
    //     return ''
    //   }
    // },
    someDataLoaded() {
      return (
        this.usersInitialized ||
        this.battleInitialized ||
        this.messagesInitialized
      );
    },
    allDataLoaded() {
      return (
        this.settingsInitialized &&
        this.usersInitialized &&
        this.battleInitialized &&
        this.messagesInitialized
      );
    },
    // leaderboard() {
    //   const allUsers = this.roomPlayers.concat(this.users);
    //   return allUsers.reduce((uniqueUsers, user) => {
    //     return uniqueUsers.map(user => user.username).includes(user.username) ? uniqueUsers : [...uniqueUsers, user]
    //   }, [])
    // },
    seekAttention() {
      if (this.battleStatus.battleOngoing) {
        return ["animated pulse seek-attention"];
      } else {
        return null;
      }
    },
    announcerWindow() {
      let status = this.announcement.status || "normal";
      let content = this.announcement.content;

      if (this.countdown > 0) {
        status = "warning";
        content = `<p><small class='m-0'>Battle starting in...</small></p><span class="timer highlight">${this.countdown}</span>`;
      }

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

      if (currentUserIndex === -1) {
        if (this.currentUserIsModerator)
          console.log("Current user not found in list of room users!");
        return null
      } else {
        return this.users[currentUserIndex];
      }
    },
    currentUserIsModerator() {
      return this.currentUserId === this.room.moderator_id;
    },
    invitedUsers() {
      if (this.battleStage === 0) { return [] }
      // return this.battle.players
      return this.users.filter(user => user.invite_status === 'invited')
    },
    confirmedUsers() {
      if (!this.battle.players) {
        return [];
      } else {
        return this.battle.players.filter(
          user => user.invite_status == "confirmed"
        );
      }
    },
    allConfirmed() {
      return this.battleStage === 2 && this.invitedUsers.length === 0;
    },
    // STATUSES
    roomStatus() {
      if (this.battleStage === 4) {
        return "war";
      } else if (this.battleStage === 3) {
        return "countdown";
      } else if (this.battleStage === 2) {
        return "battle-confirmed";
      } else if (this.battleStage === 1) {
        return "battle-loaded";
      } else {
        return "peace";
      }
    },
    // Battle Status
    // 1 - Loaded (no start_time, no confirmed players)
    // 2 - Can Start (no start_time, at least one confirmed player)
    // 3 - Countdown (start_time exists, no end_time and countdown not zero)
    // 4 - Battle Ongoing (start_time exists, no end_time)
    // 5 - Battle Over (end_time exists)
    battleStatus() {
      return {
        battleLoaded: this.battleLoaded,
        readyToStart: this.readyToStart,
        battleCountdown: this.battleCountdown,
        battleOngoing: this.battleOngoing,
        battleOver: this.battleOver,
        showBattleInfo: this.battleOngoing || this.battleOver
      };
    },
    battleStage() {
      let stage;
      if (this.battleLoaded && !this.readyToStart) stage = 1;
      else if (this.readyToStart) stage = 2;
      else if (this.battleCountdown) stage = 3;
      else if (this.battleOngoing) stage = 4;
      else stage = 0;

      this.$set(this.battle, "stage", stage);
      return stage;
    },
    battleLoaded() {
      if (!this.battle.id) return false;

      return !this.battle.start_time && !this.battle.end_time;
    },
    readyToStart() {
      if (!this.battle.id) return false;

      return (
        !this.battle.start_time &&
        !this.battle.end_time &&
        this.confirmedUsers.length > 0
      );
    },
    readyForBattle() {
      if (!this.battle.id && !this.currentUser) return false;

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
    roomSoundON() {
      return this.room.sound || this.currentUserIsModerator
    },
    sfxON() {
      return this.roomSoundON && this.settings.user.sfx
    },
    musicON() {
      return this.roomSoundON && this.settings.user.music
    },
  },
  methods: {
    sendCable(action, data) {
      this.$cable.perform({
        channel: "RoomChannel",
        action: action,
        data: data
      });
    },
    debouncedSendCable: _.debounce((cable, action, data) => {
      cable.perform({
        channel: "RoomChannel",
        action: action,
        data: data
      });
    }, 1000),
    // =============
    //     ROOM
    // =============
    openModal() {
      this.focus = 'modal'
      this.isolateFocus = true
    },
    closeModal() {
      if (this.isolateFocus && this.focus === 'modal') {
        this.isolateFocus = false
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
      console.log(updatedSettings)
      this.sendCable("update_user_settings", { user: updatedSettings.user });
    },
    checkCurrentUserConnection() {
      setInterval(_ => {
        const currentUserIndex = this.users.findIndex(
          e => e.id === this.currentUser.id
        );

        if (currentUserIndex === -1) this.sendCable("resubscribe");
      }, 60000);
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
    notifyEvent(event) {
      if (this.currentUserIsModerator && !this.viewMode) {
        this.sendCable("trigger_event", { event: event });
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
      if (this.sfxON) {
        if (options.interrupt) speechSynthesis.cancel();
        const msg = new SpeechSynthesisUtterance(message);
        const voices = speechSynthesis.getVoices();
        const voiceURI = options.voiceURI || "Google US English";
        const soundFX = options.fx
        const fxVolume = options.fxVolume
        const fxPlayAt = options.fxPlayAt || 'asap'
        msg.voice =
          voices[voices.findIndex(e => e.voiceURI === voiceURI)];
        msg.rate = 1.1;
        msg.pitch = 0.85;
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
    createBattle(challenge) {
      this.battleLoading = true
      const challengeIdSlug = this.parseChallengeInput(challenge)
        .challengeIdSlug;
      this.sendCable("create_battle", {
        challenge_id: challengeIdSlug,
        time_limit: this.timeLimit * 60
      });
    },
    deleteBattle() {
      if (this.battleLoaded) this.sendCable("delete_battle", { battle_id: this.battle.id });
    },
    // updateBattle(battle) {
    //   battle.deleted ? this.battle = null : this.battle = battle
    // },
    parseChallengeInput(input) {
      const urlRegex = /^(https:\/\/)?www\.codewars\.com\/kata\/(?<challengeIdSlug>.+)\/train\/(?<language>.+)$/;
      const matchData = input.match(urlRegex);
      if (matchData) {
        return {
          challengeIdSlug: matchData.groups.challengeIdSlug,
          language: matchData.groups.language
        };
      } else {
        return {
          challengeIdSlug: input,
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
          time_limit: this.timeLimit * 60
        });
      }
    },
    endBattle() {
      if (this.currentUserIsModerator && this.battleStage > 3)
        this.sendCable("update_battle", {
          battle_action: 'end',
          battle_id: this.battle.id,
        });
      this.stopAmbiance();
      this.challengeInput = "";
      this.announce({
        content: `<i class="fas fa-peace"></i> The battle for <span class='chat-highlight'>${this.battle.challenge.name}</span> is over.`,
      });
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
        user_id: userId ? userId : this.currentUser.id,
        battle_id: this.battle.id
      });
    },
    getRoomPlayers(userId) {
      this.sendCable("get_room_players");
    },
    openCodewars() {
      if (this.battle.challenge.language === null)
        this.battle.challenge.language = "ruby";
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
    playSoundFx(fxName, volume = 1) {
      // volume = volume || 1
      const soundFX = this.sounds.fx[fxName]
      if (!soundFX) return

      soundFX.pause();
      soundFX.currentTime = 0;
      soundFX.volume = volume;
      if (this.sfxON) soundFX.play();
    },
    startCountdown(countdown) {
      this.countdown = countdown;
      const timer = setInterval(() => {
        if (this.countdown > 1) {
          this.countdown -= 1;
        } else {
          this.countdown = 0;
          clearInterval(timer);
          if (this.currentUser.invite_status === "confirmed" && !this.viewMode)
            this.openCodewars();
          this.startClock();
          // this.startAmbiance();
        }
      }, 1000);
    },
    startClock() {
      clearInterval(this.clockInterval);
      this.clockInterval = setInterval(() => {
        if (this.battle.stage === 4) {
          if (this.battle.time_limit > 0) {
            const clockTime = this.timeRemainingInSeconds() > 0 ? this.timeRemainingInSeconds() : 0;
            this.announce({ content: `<span class='timer highlight'>${this.formatDuration(clockTime)}</span>` });
            if (
              this.timeRemainingInSeconds() > 301 &&
              this.timeRemainingInSeconds() <= 302
            ) {
              this.speak("WARNING! 5min remaining!", { cancelPrevious: true });
            } else if (
              this.timeRemainingInSeconds() > 121 &&
              this.timeRemainingInSeconds() <= 122
            ) {
              this.speak("WARNING! 2min remaining!", { cancelPrevious: true });
            } else if (
              this.timeRemainingInSeconds() > 61 &&
              this.timeRemainingInSeconds() <= 62
            ) {
              this.speak("WARNING! 1min remaining!", { cancelPrevious: true });
            } else if (
              this.timeRemainingInSeconds() > 10 &&
              this.timeRemainingInSeconds() <= 11
            ) {
              this.setBackgroundVolume()
              // this.speak(Math.round(this.timeRemainingInSeconds()), true)
              this.playSoundFx("countdown");
            } else if (this.timeRemainingInSeconds() <= 0) {
              this.endBattle();
              clearInterval(this.clockInterval);
            }
          } else {
            const clockTime = this.timeSpentInSeconds();
            this.announce({
              content: `<p class='highlight'><small>TIME ELAPSED</small></p><span class="timer highlight no-limit">${this.formatDuration(clockTime)}</span>`
            });
          }
        } else {
          clearInterval(this.clockInterval);
        }
      }, 1000);
    },
    timeSpentInSeconds() {
      return (Date.now() - Date.parse(this.battle.start_time)) / 1000;
    },
    timeRemainingInSeconds() {
      return this.battle.time_limit - this.timeSpentInSeconds();
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
        // array[index] = user; // Vue cannot detect change in the array with this method
        result.oldElement = array[elementIndex];
        array.splice(elementIndex, 1, element);
      }
      return result;
    },
    pushToUsers(user) {
      if (this.users) this.pushToArray(this.users, user);

      if (this.battle.players) this.pushToPlayers(user);
    },
    pushToPlayers(user) {
      if (this.battle.players)
        if (user.invite_status === "eligible" || user.invite_status === "ineligible") {
          this.removeFromArray(this.battle.players, user);
        } else {
          this.pushToArray(this.battle.players, user);
      }
    },
    completedIn(battle, user) {
      return (new Date(user.completed_at) - new Date(battle.start_time)) / 1000; // duration in seconds
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
    editTimeLimit(step) {
      const max = 90;
      const min = 0;
      if (this.timeLimit + step >= min && this.timeLimit + step <= max)
        this.timeLimit += step;
      this.debouncedSendCable(this.$cable, "update_battle", {
        battle_action: "update",
        battle_id: this.battle.id,
        countdown: this.countdownDuration,
        battle: { id: this.battle.id, time_limit: this.timeLimit * 60 }
      });
    }
  },
  channels: {
    RoomChannel: {
      connected() {
        // if (this.currentUserIsModerator)
          // console.log("WebSockets connected to RoomChannel.");
      },
      rejected() {},
      received(data) {
        switch (data.subchannel) {
          case "action":
            switch (data.payload.action) {
              case "update-countdown":
                this.countdown = data.payload.data.countdown;
                break;

              case "start-countdown":
                // this.sendCable('invitation', { battle_id: this.battle.id, invite_action: 'uninvite-unconfirmed' })
                this.startCountdown(data.payload.data.countdown);
                this.playSoundFx("countdown");
                break;

              case "voice-announce":
                this.speak(data.payload.message, data.payload.options);
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
                this.chat.messages = data.payload.messages;
                this.chat.authors = data.payload.authors;
                // if (this.currentUserIsModerator) console.info(`Refreshed all messages`)
                this.messagesInitialized = true;
                break;

              default:
                this.chat.messages.push(data.payload);
                break;
            }
            break;

          case "logs":
            if (this.currentUserIsModerator) console.info("LOGS", data.payload);
            break;

          case "settings":
            switch (data.payload.action) {
              case "user":
                this.settings.user = data.payload.settings;
                this.settingsInitialized = true;
                break;

              case "room":
                break;
            }
            break;  

          case "users":
            switch (data.payload.action) {
              case "add":
                this.pushToUsers(data.payload.user);
                break;

              case "remove":
                this.users = this.users.filter(
                  e => e.id !== data.payload.user.id
                );
                // this.removeFromUsers(data.payload.user);
                // if (this.currentUserIsModerator) console.info(`Removed user ${data.payload.user.username}`)
                break;

              case "all":
                this.users = data.payload.users;
                this.users.forEach(user => this.pushToUsers(user));
                this.usersInitialized = true;
                if (this.currentUserIsModerator)
                  // console.info(`Refreshed all users`);
                break;

              case "room-players":
                this.roomPlayers = data.payload.players;
                this.roomPlayersInitialized = true;
                if (this.currentUserIsModerator)
                  // console.info(`Refreshed all room players`);
                break;
            }
            break;

          case "leaderboard":
            switch (data.payload.action) {
              case "update":
                this.leaderboard = data.payload.leaderboard;
                break;

              default:
                this.leaderboard = data.payload.leaderboard;
            }
            break;

          case "battles":
            switch (data.payload.action) {
              case "active":
                if (data.payload.battle) {
                  this.battleLoading = false
                  this.battle = data.payload.battle
                  if (this.battleOngoing) this.startClock();
                  this.battleInitialized = true;
                } else {
                  this.battle = {}
                }

                break;

              case "player":
                this.pushToPlayers(data.payload.user);
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
      disconnected() {}
    }
  },
  mounted() {
    speechSynthesis.cancel();

    this.$cable.subscribe({
      channel: "RoomChannel",
      room_id: this.room.id,
      user_id: this.currentUserId
    });
    this.$root.$on("announce", message => this.announce(message));
    this.$root.$on("send-chat-message", message =>
      this.sendChatMessage(message)
    );
    this.$root.$on(
      "change-volume-ambiance",
      volume => (this.sounds.volumeAmbiance = volume)
    );
    this.$root.$on("open-user-settings", _ => this.openSettings());
    this.$root.$on("toggle-settings", _ => this.toggleSettings());
    this.$root.$on("update-settings", settings => this.updateSettings(settings));
    this.$root.$on("close-modal", _ => this.closeModal());
    this.$root.$on("create-battle", challenge => this.createBattle(challenge));
    this.$root.$on("delete-battle", () => this.deleteBattle());
    this.$root.$on("fetch-challenges", (userId = null) => this.fetchChallenges(userId));
    this.$root.$on("get-room-players", () => this.getRoomPlayers());
    this.$root.$on("push-user", user => this.pushToUsers(user));
    this.$root.$on("remove-user", user => this.removeFromUsers(user));
    this.$root.$on("invite-user", userId => this.invitation("invite", userId));
    this.$root.$on("uninvite-user", userId =>
      this.invitation("uninvite", userId)
    );
    this.$root.$on("invite-all", () => this.invitation("all"));
    this.$root.$on("invite-survivors", () => this.invitation("survivors"));
    this.$root.$on("confirm-invite", userId =>
      this.invitation("confirm", userId)
    );
    // this.$root.$on('update-battle', (battle) => this.updateBattle(battle))
    this.$root.$on("initialize-battle", () => this.initializeBattle());
    this.$root.$on("start-countdown", () => this.startCountdown());
    this.$root.$on("end-battle", () => this.userEndsBattle());
    this.$root.$on("edit-time-limit", step => this.editTimeLimit(step));
    this.$root.$on("speak", message => this.speak(message));
    this.$root.$on("play-fx", sound => this.playSoundFx(sound));
    this.$root.$on("play-ambiance", track => this.startAmbiance(track));
    this.$root.$on("toggle-music", () => this.toggleMusic());
    this.$root.$on("toggle-sound-fx", () => this.settings.user.sfx = !this.settings.user.sfx);
  }
};
</script>

<style scoped>
</style>
