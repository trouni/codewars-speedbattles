<template>
  <div id="super-container" :class="[viewMode, roomStatus]">

    <div id="spinner" v-if="!someDataLoaded" class="absolute-center display-initial">
      <div class="lds-ring"><div></div><div></div><div></div><div></div></div>
      <h3 class="animated fadeInDown faster">LOADING</h3>
    </div>

    <!-- <div id='leave-button' class="absolute-top-right-corner sign-out">
      <a href="/rooms" class="button">Leave room</a>
    </div> -->

    <div id="room" :class="['fixed-screen', { moderator: currentUserIsModerator }]">

      <div :class="['grid-item grid-header', { 'loading': !someDataLoaded }]">
        <div id="room-announcer" :class="['widget-bg', seekAttention]">
          <div class="widget">
            <h3 class="header highlight">PWD://War_Room/{{ room.name }}</h3>
            <div class="widget-body align-content-center justify-content-center">
              <span :class="['announcer mt-3', 'text-center', announcerWindow.status]" v-html="announcerWindow.content">
              </span>
            </div>
          </div>
        </div>
      </div>
      <div :class="['grid-item grid-controls', { 'loading': (!usersInitialized || !battleInitialized) }]">
        <div v-if="someDataLoaded" id="spinner" class="centered">
          <div class="lds-ring small"><div></div><div></div><div></div><div></div></div>
          <!-- <h3 class="animated fadeInDown faster">LOADING</h3> -->
        </div>
        <room-controls
          :room="room"
          :battle="battle"
          :users="users"
          :current-user="currentUser"
          :input="challengeInput"
          :current-user-is-moderator="currentUserIsModerator"
          :countdown="countdown"
          :time-limit="timeLimit"
          :battle-status="battleStatus"
          :challenge-url="challengeUrl"
          :volume-ambiance="sounds.volumeAmbiance"
        ></room-controls>
        <!-- <input type="submit" @click="test" value="test"> -->
      </div>
      <div :class="['grid-item grid-battle', { 'loading': (!usersInitialized || !battleInitialized) }]">
        <div v-if="someDataLoaded" id="spinner" class="centered">
          <div class="lds-ring small"><div></div><div></div><div></div><div></div></div>
          <!-- <h3 class="animated fadeInDown faster">LOADING</h3> -->
        </div>
        <room-battle
          :battle="battle"
          :users="users"
          :room="room"
          :countdown="countdown"
          :battle-status="battleStatus"
          :current-user-is-moderator="currentUserIsModerator"
          :view-mode="viewMode"
          :time-limit="timeLimit"
        ></room-battle>
      </div>
      <div :class="['grid-item grid-leaderboard', { 'loading': (!usersInitialized) }]">
        <div v-if="someDataLoaded" id="spinner" class="centered">
          <div class="lds-ring small"><div></div><div></div><div></div><div></div></div>
          <!-- <h3 class="animated fadeInDown faster">LOADING</h3> -->
        </div>
        <room-leaderboard
          :users="users"
          :room="room"
          :battle="battle"
          :leaderboard="leaderboard"
          :room-players="roomPlayers"
          :current-user="currentUser"
          :current-user-is-moderator="currentUserIsModerator"
        ></room-leaderboard>
      </div>
      <div :class="['grid-item grid-chat', { 'loading': !messagesInitialized }]">
        <div v-if="someDataLoaded" id="spinner" class="centered">
          <div class="lds-ring small"><div></div><div></div><div></div><div></div></div>
          <!-- <h3 class="animated fadeInDown faster">LOADING</h3> -->
        </div>
        <room-chat
          :messages="chat.messages"
          :authors="chat.authors"
          :current-user-name="currentUser.username"
          :current-user="currentUser"
        ></room-chat>
      </div>
    </div>
  </div>
</template>

<script>
  import _ from 'lodash'
  import RoomControls from '../components/room_controls.vue'
  import RoomChat from '../components/room_chat.vue'
  import RoomLeaderboard from '../components/room_leaderboard.vue'
  import RoomBattle from '../components/room_battle.vue'

  export default {
    components: {
      RoomControls,
      RoomChat,
      RoomLeaderboard,
      RoomBattle
    },
    props: {
      roomInit: Object,
      currentUserId: Number,
      currentUserInit: Object,
      // battleInit: Object,
      // messagesInit: Array
    },
    data() {
      return {
        usersInitialized: false,
        battleInitialized: false,
        messagesInitialized: false,
        roomPlayersInitialized: false,
        room: this.roomInit,
        users: [],
        roomPlayers: [],
        battle: {},
        leaderboard: {},
        chat: {
          messages: [],
          authors: []
        },
        challengeInput: '',
        controlsType: '',
        countdownDuration: 10,
        countdown: 0,
        sounds: {
          volumeFx: 1,
          volumeAmbiance: 0.4,
          volumeBackgroundAmbiance: 0.2,
          fx: {
            countdown: new Audio('../audio/countdown.mp3'),
            sword: new Audio('../audio/sword.mp3')
          },
          ambiance: [
            new Audio('../audio/bensound-epic.mp3'),
            new Audio('../audio/overpowered.mp3'),
            // new Audio('../audio/infinity-star.mp3'),
            
          ]
        },
        ambianceMusic: new Audio,
        announcement: {
          status: 'normal',
          content: `Welcome to ${this.roomInit.name}`
        },
        viewMode: new URL(window.location.href).searchParams.get("view"),
        timeLimit: 8,
      }
    },
    created() {
      // this.pushToUsers(this.currentUser);
      // setTimeout(() => { this.someDataLoaded = true }, 500);
      this.$set(this.battle, "stage", this.battleStage);
    },
    watch: {
      battleInitialized: function () {
        this.timeLimit = this.battle.time_limit || this.timeLimit;
      },
      sounds: {
        handler: function() {
          this.ambianceMusic.volume = this.sounds.volumeAmbiance;
          // this.ambianceMusic.volume === 0 ? this.pauseAmbiance() : this.resumeAmbiance()
        },
        deep: true
      },
      battleStage: function() {
        if (this.battleStage === 4) this.startAmbiance()
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
        return this.usersInitialized || this.battleInitialized || this.messagesInitialized;
      },
      // leaderboard() {
      //   const allUsers = this.roomPlayers.concat(this.users);
      //   return allUsers.reduce((uniqueUsers, user) => {
      //     return uniqueUsers.map(user => user.username).includes(user.username) ? uniqueUsers : [...uniqueUsers, user]
      //   }, [])
      // },
      seekAttention() {
        if (this.battleStatus.battleOngoing) {
          return ['animated pulse seek-attention']
        } else {
          return null
        }
      },
      soundActive() {
        return this.currentUserIsModerator
      },
      announcerWindow() {
        let status = this.announcement.status || 'normal'
        let content = this.announcement.content

        if (this.countdown > 0) {
          status = 'warning'
          content = `<p class='m-0'>Battle starting in...</p><span class="timer highlight">${this.countdown}</span>`
        }

        return {
          status: status,
          content: content
        }
      },
      challengeUrl() {
        if (this.battle.challenge) {
          const language = this.battle.challenge.language || 'ruby'
          return `${this.battle.challenge.url}/train/${language}`
        }
      },
      currentUser() {
        const currentUserIndex = this.users.findIndex((e) => e.id === this.currentUserId);

        if (currentUserIndex === -1) {
          if (this.currentUserIsModerator) console.log("Current user not found in list of room users!")
          return this.currentUserInit
        } else {
          return this.users[currentUserIndex]
        }
      },
      currentUserIsModerator() {
        return this.currentUserId === this.room.moderator_id
      },
      // invitedUsers() {
      //   if (!this.battle) { return [] }
      //   return this.battle.players
      // },
      confirmedUsers() {
        if (!this.battle.players) {
          return []
        } else {
          return this.battle.players.filter(user => user.invite_status == 'confirmed')
        }
      },
      // STATUSES
      roomStatus() {
        if (this.battleStage === 4) {
          return "war"
        } else if (this.battleStage === 3) {
          return "countdown"
        } else if (this.battleStage === 2) {
          return "battle-confirmed"
        } else if (this.battleStage === 1) {
          return "battle-loaded"
        } else {
          return "peace"
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
          showBattleInfo: this.battleOngoing || this.battleOver,
        }
      },
      battleStage() {
        let stage
        if (this.battleLoaded && !this.readyToStart) stage = 1
        else if (this.readyToStart) stage = 2
        else if (this.battleCountdown) stage = 3
        else if (this.battleOngoing) stage = 4
        else stage = 0

        this.$set(this.battle, "stage", stage);
        return stage
      },
      battleLoaded() {
        if (!this.battle.id) return false

        return !this.battle.start_time && !this.battle.end_time;
      },
      readyToStart() {
        if (!this.battle.id) return false

        return !this.battle.start_time && !this.battle.end_time && this.confirmedUsers.length > 0;
      },
      battleCountdown() {
        if (!this.battle.id) return false

        return !!this.battle.start_time &&  !this.battle.end_time && this.countdown !== 0;
      },
      battleOngoing() {
        if (!this.battle.id) return false

        return !!this.battle.start_time &&  !this.battle.end_time && this.countdown === 0;
      },
      battleOver() {
        if (!this.battle.id) return true

        return !!this.battle.end_time
      },
      // previousBattles() {
      //   if (!this.pastBattles) return []

      //   return this.pastBattles.sort((a, b) => {
      //     return new Date(b.end_time) - new Date(a.end_time)
      //   })
      // },
      // lastBattle() {
      //   return this.battle
      //   // return this.battle || this.previousBattles[0]
      // },
    },
    methods: {
      sendCable(action, data) {
        this.$cable.perform({
          channel: 'RoomChannel',
          action: action,
          data: data
        });
      },
      debouncedSendCable: _.debounce((cable, action, data) => {
        cable.perform({
          channel: 'RoomChannel',
          action: action,
          data: data
        });
      }, 1000),
      test() {
      },
      // =============
      //     ROOM
      // =============
      stripHTML(html) {
        var doc = new DOMParser().parseFromString(html, 'text/html');
        return doc.body.textContent || "";
      },
      announce(message) {
        if (message.content) {
          this.announcement = {
            status: message.status || 'normal',
            content: message.content
          }
        }
        if (message.chat && this.currentUserIsModerator) {
          const chatMessage = message.chat === true ? message.content : message.chat
          this.sendChatMessage(chatMessage, true)
        }
        
        if (message.speak && this.soundActive) {
          const speakMessage = message.speak === true ? this.stripHTML(message.content) : message.speak
          this.speak(speakMessage)
        }
      },
      sendChatMessage(message, announcement = false) {
        this.sendCable('create_message', { message: message, announcement: announcement })
        this.input = ''
      },
      speak(message) {
        var msg = new SpeechSynthesisUtterance(message)
        var voices = speechSynthesis.getVoices()
        msg.voice = voices[voices.findIndex((e) => e.voiceURI === "Google US English")]
        msg.rate = 0.9
        msg.pitch = 0.9
        msg.onend = () => {
          this.ambianceMusic.volume = this.sounds.volumeAmbiance;
        }
        this.ambianceMusic.volume = Math.min(this.sounds.volumeAmbiance, this.sounds.volumeBackgroundAmbiance);
        speechSynthesis.speak(msg)
      },
      // =============
      //     BATTLE
      // =============
      createBattle(challenge) {
        // this.timeLimit = 0;
        const challengeIdSlug = this.parseChallengeInput(challenge).challengeIdSlug
        this.sendCable('create_battle', { challenge_id: challengeIdSlug, time_limit: this.timeLimit });
      },
      deleteBattle() {
        this.sendCable('delete_battle', { battle_id: this.battle.id });
      },
      // updateBattle(battle) {
      //   battle.deleted ? this.battle = null : this.battle = battle
      // },
      parseChallengeInput(input) {
        const urlRegex = /^(https:\/\/)?www\.codewars\.com\/kata\/(?<challengeIdSlug>.+)\/train\/(?<language>.+)$/;
        const matchData = input.match(urlRegex);
        if (matchData) {
          return {
            "challengeIdSlug": matchData.groups.challengeIdSlug,
            "language": matchData.groups.language
          };
        } else {
          return {
            "challengeIdSlug": input,
            "language": null
          }
        }
      },
      initializeBattle() {
        this.sendCable('update_battle', { battle_action: 'start', battle_id: this.battle.id, countdown: this.countdownDuration, time_limit: this.timeLimit });
      },
      endBattle() {
        this.stopAmbiance();
        if (this.currentUserIsModerator) this.sendCable('update_battle', { battle_action: 'end', battle_id: this.battle.id });
        this.challengeInput = '';
      },
      fetchChallenges(userId) {
        this.sendCable('fetch_user_challenges', { user_id: userId, battle_id: this.battle.id });
      },
      getRoomPlayers(userId) {
        this.sendCable('get_room_players')
      },
      openCodewars() {
        if (this.battle.challenge.language === null) this.battle.challenge.language = 'ruby';
        window.open(this.challengeUrl)
      },
      startAmbiance() {
        if (!this.ambianceMusic.paused) return;

        this.ambianceMusic = this.sounds.ambiance[Math.floor(Math.random() * this.sounds.ambiance.length)]
        // this.ambianceMusic.loop = true
        this.ambianceMusic.volume = this.sounds.volumeAmbiance;
        this.ambianceMusic.onended = () => {
          this.startAmbiance();
        };
        if (this.soundActive) this.ambianceMusic.play();
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
      startCountdown(countdown) {
        this.announce({
              content: `<h2>🍻</h2><p>Battle starting in ${countdown}s... Time for a drink!</p>`,
              chat: true
            });
        this.countdown = countdown
        const timer = setInterval(() => {
          if (this.countdown > 1) {
            this.countdown -= 1
          } else {
            this.countdown = 0
            clearInterval(timer);
            this.announce({
              content: `<i class="fas fa-rocket mr-1"></i> The battle for <span class="chat-highlight">${this.battle.challenge.name}</span> has begun!`,
              chat: true
            });
            if (this.currentUser.invite_status === 'confirmed' && !this.viewMode) this.openCodewars();
            this.startClock();
            // this.startAmbiance();
          }
        }, 1000)
      },
      startClock() {
        const clock = setInterval(() => {
          if (this.battle.stage === 4) {
            let clockTime;
            if (this.battle.time_limit > 0) {
              if (this.timeRemainingInSeconds() > 121 && this.timeRemainingInSeconds() <= 122) {
                this.announce({ speak: "WARNING! 2min left" })
              } else if (this.timeRemainingInSeconds() > 61 && this.timeRemainingInSeconds() <= 62) {
                this.announce({ speak: "WARNING! 1min left" })
              } else if (this.timeRemainingInSeconds() > 10 && this.timeRemainingInSeconds() <= 11) {
                this.ambianceMusic.volume = Math.min(this.sounds.volumeAmbiance, this.sounds.volumeBackgroundAmbiance);
                if (this.soundActive) this.sounds.fx.countdown.play();
              } else if (this.timeRemainingInSeconds() <= 0) {
                this.endBattle();
              }
              clockTime = this.timeRemainingInSeconds() > 0 ? this.timeRemainingInSeconds() : 0;
            } else {
              clockTime = this.timeSpentInSeconds();
            }
            this.announce({ content: `<span class='timer highlight'>${this.formatDuration(clockTime)}</span>` });
          } else {
            clearInterval(clock);
            this.announce({
              content: `<i class="fas fa-peace"></i> The battle for <span class='chat-highlight'>${this.battle.challenge.name}</span> is over.`,
              chat: true
            });
          }
        }, 1000)
      },
      timeSpentInSeconds() {
        return (Date.now() - Date.parse(this.battle.start_time)) / 1000
      },
      timeRemainingInSeconds() {
        return (this.battle.time_limit * 60 - this.timeSpentInSeconds())
      },
      formatDuration(durationInSeconds) {
        if (durationInSeconds < 0) durationInSeconds = 0
        const hours = Math.floor(durationInSeconds / 60 / 60)
        const minutes = Math.floor(durationInSeconds / 60) % 60
        const seconds = Math.floor(durationInSeconds - hours * 60 * 60 - minutes * 60)
        return `${hours > 0 ? `${String(hours).padStart(2, '0')}:` : ''}${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
      },
      formatDurationForSpeech(durationInSeconds) {
        if (durationInSeconds < 0) durationInSeconds = 0
        const hours = Math.floor(durationInSeconds / 60 / 60)
        const minutes = Math.floor(durationInSeconds / 60) % 60
        const seconds = Math.floor(durationInSeconds - hours * 60 * 60 - minutes * 60)
        return `${hours > 0 ? `${hours}hr ` : ''}${minutes}min${seconds > 0 ? ` ${seconds}sec` : ''}`
      },
      // =============
      //     USERS
      // =============
      pushToArray(array, element) {
        const result = { newElement: element }
        const elementIndex = array.findIndex((e) => e.id === element.id);
        if (elementIndex === -1) {
          array.push(element);
          // if (this.currentUserIsModerator) console.info('Added element:', element)
        } else {
          // array[index] = user; // Vue cannot detect change in the array with this method
          result.oldElement = array[elementIndex]
          array.splice(elementIndex, 1, element)
          // if (this.currentUserIsModerator) console.info('Updated element:', element)
        }
        return result
      },
      pushToUsers(user) {
        // if (this.currentUserIsModerator) console.info('Pushing to Users', user)
        if (this.users) this.pushToArray(this.users, user)

        if(this.battle.players) this.pushToPlayers(user);
      },
      pushToPlayers(user) {
        if (user.invite_status === 'eligible' || user.invite_status === 'ineligible') {
          // if (this.currentUserIsModerator) console.info('Removing from Players', user)
          if (this.battle.players) this.removeFromArray(this.battle.players, user);
        } else {
          // if (this.currentUserIsModerator) console.info('Pushing to Players', user)
          if (this.battle.players) {
            const result = this.pushToArray(this.battle.players, user)
            if (result.oldElement && result.oldElement.invite_status === 'confirmed' && result.newElement.invite_status === 'survived') {
              if (this.currentUserIsModerator) {
                if (this.soundActive) this.sounds.fx.sword.play();
                this.announce({
                  content: `<i class="fas fa-shield-alt"></i> Challenge completed by <span class="chat-highlight">@{${user.username}}</span>`,
                  chat: true,
                  speak: `Challenge completed by ${user.name || user.username} in ${this.formatDurationForSpeech(this.completedIn(this.battle, user))}`
                });
              }
            }
          }
        }
      },
      completedIn(battle, user) {
        return (new Date(user.completed_at) - new Date(battle.start_time)) / 1000 // duration in seconds
      },
      removeFromArray(array, element) {
        const elementIndex = array.findIndex((e) => e.id === element.id);
        if (elementIndex !== -1) {
          array.splice(elementIndex, 1)
            // if (this.currentUserIsModerator) console.info('Removed element:', element)
        }
      },
      removeFromUsers(user) {
        if (this.users) this.removeFromArray(this.users, user);
      },
      invitation(inviteAction, userId = null) {
        this.sendCable('invitation', { battle_id: this.battle.id, invite_action: inviteAction, user_id: userId })
      },
      editTimeLimit(step) {
        const max = 60;
        const min = 0;
        if (this.timeLimit + step >= min && this.timeLimit + step <= max) this.timeLimit += step;
        this.debouncedSendCable(this.$cable, 'update_battle', { battle_action: 'update', battle_id: this.battle.id, countdown: this.countdownDuration, battle: { id: this.battle.id, time_limit: this.timeLimit } });
      },
    },
    channels: {
      RoomChannel: {
        connected() {
          if (this.currentUserIsModerator) console.log('WebSockets connected to RoomChannel.')
        },
        rejected() {},
        received(data) {
          switch (data.subchannel) {
            case "action":
            switch (data.payload.action) {
              case 'update-countdown':
              this.countdown = data.payload.data.countdown;
              break;

              case 'start-countdown':
              // this.sendCable('invitation', { battle_id: this.battle.id, invite_action: 'uninvite-unconfirmed' })
              this.startCountdown(data.payload.data.countdown);
              if (this.soundActive) this.sounds.fx.countdown.play();
              break;

              default:
              if (this.currentUserIsModerator) console.log("Received data, without matching subchannel:", data);
            }
            break;

            case "chat":
            switch (data.payload.action) {
              case "all":
              this.chat.messages = data.payload.messages
              this.chat.authors = data.payload.authors
              // if (this.currentUserIsModerator) console.info(`Refreshed all messages`)
              this.messagesInitialized = true;
              break;

              default:
              this.chat.messages.push(data.payload)
              break;
            }
            break;

            case "logs":
            if (this.currentUserIsModerator) console.info("LOGS",data.payload)
            break;

            case "users":
            switch (data.payload.action) {
              case "add":
              this.pushToUsers(data.payload.user);
              break;

              case "remove":
              this.users = this.users.filter(e => e.id !== data.payload.user.id);
              // this.removeFromUsers(data.payload.user);
              // if (this.currentUserIsModerator) console.info(`Removed user ${data.payload.user.username}`)
              break;

              case "all":
              this.users = data.payload.users;
              this.users.forEach(user => this.pushToUsers(user));
              this.usersInitialized = true;
              if (this.currentUserIsModerator) console.info(`Refreshed all users`)
              break;

              case "room-players":
              this.roomPlayers = data.payload.players
              this.roomPlayersInitialized = true;
              if (this.currentUserIsModerator) console.info(`Refreshed all room players`)
              break;
            }
            break;

            case "leaderboard":
            switch (data.payload.action) {
              case 'update':
              this.leaderboard = data.payload.leaderboard;
              break;

              default:
              this.leaderboard = data.payload.leaderboard;
            }
            break;

            case "battles":
            switch (data.payload.action) {
              case "active":
              if (data.payload.battle) this.battle = data.payload.battle;
              if (this.battle.stage > 0 && this.battle.challenge) {
                this.challengeInput = this.battle.challenge.name
              } else {
                this.challengeInput = ''
              }
              if (this.battleOngoing) this.startClock();
              this.battleInitialized = true;
              if (this.currentUserIsModerator) console.info(`Refreshed active battle`);
              break;

              case "player":
              this.pushToPlayers(data.payload.user);
              break;

              default:
              break;
            }
            break;

            default:
            if (this.currentUserIsModerator) console.log("Received data, without matching subchannel:", data)
          }
        },
        disconnected() {}
      }
    },
    mounted () {
      this.$cable.subscribe({ channel: 'RoomChannel', room_id: this.room.id, user_id: this.currentUserId });
      this.$root.$on('announce', (message) => this.announce(message))
      this.$root.$on('send-chat-message', (message) => this.sendChatMessage(message))
      this.$root.$on('change-volume-ambiance', (volume) => this.sounds.volumeAmbiance = volume)
      this.$root.$on('create-battle', (challenge) => this.createBattle(challenge))
      this.$root.$on('delete-battle', () => this.deleteBattle())
      this.$root.$on('fetch-challenges', (userId) => this.fetchChallenges(userId))
      this.$root.$on('get-room-players', () => this.getRoomPlayers())
      this.$root.$on('push-user', (user) => this.pushToUsers(user))
      this.$root.$on('remove-user', (user) => this.removeFromUsers(user))
      this.$root.$on('invite-user', (userId) => this.invitation("invite", userId))
      this.$root.$on('uninvite-user', (userId) => this.invitation("uninvite", userId))
      this.$root.$on('invite-all', () => this.invitation("all"))
      this.$root.$on('invite-survivors', () => this.invitation("survivors"))
      this.$root.$on('confirm-invite', (userId) => this.invitation("confirm", userId))
      // this.$root.$on('update-battle', (battle) => this.updateBattle(battle))
      this.$root.$on('initialize-battle', () => this.initializeBattle())
      this.$root.$on('start-countdown', () => this.startCountdown())
      this.$root.$on('end-battle', () => this.endBattle())
      this.$root.$on('edit-time-limit', (step) => this.editTimeLimit(step))
      this.$root.$on('speak', (message) => this.speak(message))
    },
  }
</script>

<style scoped>

</style>
