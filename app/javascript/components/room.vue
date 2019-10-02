<template>
  <div id="room" :class="[roomStatus, { moderator: this.currentUserIsModerator }]">

    <div class="grid-item grid-header">
      <div id="room-announcer" :class="['widget-bg', seekAttention]">
        <div class="widget">
          <h3 class="header highlight">PWD://War_Room/{{ room.name }}</h3>
          <div class="widget-body align-content-center justify-content-center pt-0">
            <span :class="['announcer', 'text-center', announcerWindow.status]" v-html="announcerWindow.content">
            </span>
          </div>
        </div>
      </div>
    </div>
    <div class="grid-item grid-chat">
      <room-chat :messages="messages"></room-chat>
    </div>
    <div class="grid-item grid-battle">
      <room-battle :battle="activeBattle" :last-battle="lastBattle" :users="users" :room="room" :countdown="countdown" :battle-status="battleStatus" :current-user-is-moderator="currentUserIsModerator"></room-battle>
    </div>
    <div class="grid-item grid-leaderboard">
      <room-leaderboard :leaderboard="leaderboard" :users="users" :room="room" :room-players="roomPlayers" :current-user="currentUser" :current-user-is-moderator="currentUserIsModerator"></room-leaderboard>
    </div>
    <div class="grid-item grid-controls">
      <room-controls :room="room" :battle="activeBattle" :users="users" :current-user="currentUser" :input="challengeInput" :current-user-is-moderator="currentUserIsModerator" :countdown="countdown" :battle-status="battleStatus"></room-controls>
    </div>
  </div>
</template>

<script>
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
      usersInit: Array,
      roomPlayersInit: Array,
      battlesInit: Object,
      currentUserId: Number,
      currentUserInit: Object,
      messagesInit: Array,
    },
    data() {
      return {
        room: this.roomInit,
        users: this.usersInit,
        roomPlayers: this.roomPlayersInit,
        activeBattle: this.battlesInit.active,
        pastBattles: this.battlesInit.finished,
        messages: this.messagesInit,
        challengeInput: '',
        controlsType: '',
        countdownDuration: 5,
        countdown: 0,
        announcement: {
          status: 'normal',
          content: `Welcome to ${this.roomInit.name}`
        },
      }
    },
    created() {
      this.pushToUsers(this.currentUser);
    },
    computed: {
      leaderboard() {
        const allUsers = this.roomPlayers.concat(this.users);
        return allUsers.reduce((uniqueUsers, user) => {
          return uniqueUsers.map(user => user.username).includes(user.username) ? uniqueUsers : [...uniqueUsers, user]
        }, [])
      },
      seekAttention() {
        if (this.battleStatus.battleOngoing) {
          return ['animated pulse seek-attention']
        } else {
          return null
        }
      },
      announcerWindow() {
        let status = this.announcement.status || 'normal'
        let content = this.announcement.content

        if (this.countdown > 0) {
          status = 'warning'
          content = `Battle starting in... <span class="timer highlight">${this.countdown}</span>`
        }

        return {
          status: status,
          content: content
        }
      },
      currentUser() {
        const currentUserIndex = this.users.findIndex((e) => e.id === this.currentUserId);

        if (currentUserIndex === -1) {
          console.log("Current user not found in list of room users!")
          return this.currentUserInit
        } else {
          return this.users[currentUserIndex]
        }
      },
      currentUserIsModerator() {
        return this.currentUserId === this.room.moderator_id
      },
      // invitedUsers() {
      //   if (!this.activeBattle) { return [] }
      //   return this.activeBattle.players
      // },
      confirmedUsers() {
        if (!this.activeBattle) { return [] }
        return this.activeBattle.players.filter(user => user.invite_status == 'confirmed')
      },
      // STATUSES
      roomStatus() {
        if (!this.battleStatus.battleLoaded) {
          return "peace"
        // } else if (!this.battleStatus.readyToStart) {
        //   return "preparation"
        } else if (!this.battleStatus.battleInitialized && this.countdown === 0) {
          return "brink-of-war"
        } else if (this.countdown > 0 || !this.battleStatus.battleOngoing) {
          return "countdown"
        } else if (!this.battleStatus.lastBattleOver) {
          return "war"
        } else {
          return "peace"
        }
      },
      battleStatus() {
        return {
          battleLoaded: this.battleLoaded,
          readyToStart: this.readyToStart,
          battleInitialized: this.battleInitialized,
          battleOngoing: this.battleOngoing,
          lastBattleOver: this.lastBattleOver,
          showBattleInfo: this.battleOngoing || this.lastBattleOver,
        }
      },
      battleLoaded() {
        return !!this.activeBattle;
      },
      readyToStart() {
        if (!this.activeBattle) return false

        return this.confirmedUsers && this.confirmedUsers.length > 0;
      },
      battleInitialized() {
        if (!this.activeBattle) return false

        return this.activeBattle.start_time !== null;
      },
      battleOngoing() {
        if (!this.activeBattle) return false

        return this.activeBattle.start_time !== null && this.countdown === 0;
      },
      previousBattles() {
        if (!this.pastBattles) return []

        return this.pastBattles.sort((a, b) => {
          return new Date(b.end_time) - new Date(a.end_time)
        })
      },
      lastBattle() {
        return this.activeBattle || this.previousBattles[0]
      },
      lastBattleOver() {
        if (this.lastBattle) return this.lastBattle.end_time !== null
      },
    },
    methods: {
      sendCable(action, data) {
        this.$cable.perform({
          channel: 'RoomChannel',
          action: action,
          data: data
        });
      },
      // =============
      //     ROOM
      // =============
      announce(message) {
        this.announcement = {
          status: message.status || 'normal',
          content: message.content
        }
      },
      sendChatMessage(content) {
        this.sendCable('create_message', { message: content })
        this.input = ''
      },
      // =============
      //     BATTLE
      // =============
      createBattle(challenge) {
        const challengeIdSlug = this.parseChallengeInput(challenge).challengeIdSlug
        this.sendCable('create_battle', { challenge_id: challengeIdSlug });
      },
      deleteBattle() {
        this.sendCable('delete_battle', { battle_id: this.activeBattle.id });
      },
      // updateBattle(battle) {
      //   battle.deleted ? this.activeBattle = null : this.activeBattle = battle
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
        this.sendCable('update_battle', { battle_action: 'start', battle_id: this.activeBattle.id, countdown: this.countdownDuration });
      },
      endBattle() {
        this.sendCable('update_battle', { battle_action: 'end', battle_id: this.activeBattle.id });
      },
      fetchChallenges(userId) {
        this.sendCable('fetch_user_challenges', { user_id: userId, battle_id: this.activeBattle.id })
      },
      openCodeWars() {
        if (this.activeBattle.challenge.language === null) { this.activeBattle.challenge.language = 'ruby' }
        const challengeUrl = `${this.activeBattle.challenge.url}/train/${this.activeBattle.challenge.language}`
        window.open(challengeUrl)
      },
      startCountdown(countdown) {
        this.countdown = countdown
        const timer = setInterval(() => {
          if (this.countdown > 1) {
            this.countdown -= 1
          } else {
            this.countdown = 0
            clearInterval(timer);
            if (!this.currentUserIsModerator) this.openCodeWars();
          }
        }, 1000)
      },
      // =============
      //     USERS
      // =============
      pushToUsers(user) {
        const index = this.users.findIndex((e) => e.id === user.id);

        if (index === -1) {
            this.users.push(user);
        } else {
            // this.users[index] = user; // Vue cannot detect change in the array with this method
            this.users.splice(index, 1, user)
        }
      },
      removeFromUsers(user) {
        this.users = this.users.filter(e => e.id != user.id)
      },
      invitation(inviteAction, userId = null) {
        this.sendCable('invitation', { battle_id: this.activeBattle.id, invite_action: inviteAction, user_id: userId })
      },
    },
    channels: {
      RoomChannel: {
        connected() {
          console.log('WebSockets connected to RoomChannel.')
        },
        rejected() {},
        received(data) {
          switch (data.subchannel) {
            case "action":
            switch (data.payload.action) {
              case 'update-countdown':
              this.countdown = data.payload.data.countdown;
              break;

              case 'launch-codewars':
              if (!this.currentUserIsModerator) this.openCodeWars();
              break;

              case 'start-countdown':
              this.startCountdown(data.payload.data.countdown);
              break;

              default:
              console.log("Received data, without matching subchannel:", data);
            }
            break;

            case "chat":
            this.messages.push(data.payload)
            break;

            case "logs":
            console.info(data.payload)
            break;

            case "users":
            switch (data.payload.action) {
              case "add":
              this.pushToUsers(data.payload.user);
              console.info(`Added user ${data.payload.user.username}`)
              break;

              case "remove":
              this.removeFromUsers(data.payload.user);
              console.info(`Removed user ${data.payload.user.username}`)
              break;

              case "all":
              this.users = data.payload.users
              console.info(`Refreshed all users`)
              break;
            }
            break;

            case "battles":
            this.activeBattle = data.payload.battles.active
            this.pastBattles = data.payload.battles.finished
            console.info(`Refreshed all battles`)
            break;

            default:
            console.log("Received data, without matching subchannel:", data)
          }
        },
        disconnected() {}
      }
    },
    mounted () {
      this.$cable.subscribe({ channel: 'RoomChannel', room_id: this.room.id, user_id: this.currentUserId });
      this.$root.$on('announce', (message) => this.announce(message))
      this.$root.$on('send-chat-message', (message) => this.sendChatMessage(message))
      this.$root.$on('create-battle', (challenge) => this.createBattle(challenge))
      this.$root.$on('delete-battle', () => this.deleteBattle())
      this.$root.$on('fetch-challenges', (userId) => this.fetchChallenges(userId))
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
    },
  }
</script>

<style scoped>

</style>
