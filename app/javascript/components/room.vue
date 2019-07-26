<template>
  <div id="room" v-if="loaded" :class="[roomStatus, { moderator: this.currentUserIsModerator }]">

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
      <room-chat :chat-id="room.chat_id" :user-id="currentUserId"></room-chat>
    </div>
    <div class="grid-item grid-battle">
      <room-battle :battle="battle" :last-battle="lastBattle" :users="users" :room="room" :countdown="countdown" :battle-status="battleStatus" :current-user-is-moderator="currentUserIsModerator"></room-battle>
    </div>
    <div class="grid-item grid-leaderboard">
      <room-leaderboard :leaderboard="leaderboard" :users="users" :room="room" :current-user="currentUser" :current-user-is-moderator="currentUserIsModerator"></room-leaderboard>
    </div>
    <div class="grid-item grid-controls">
      <room-controls-mod :room="room" :battle="battle" :users="users" :current-user="currentUser" :input="challengeInput" :current-user-is-moderator="currentUserIsModerator" :countdown="countdown" :battle-status="battleStatus"></room-controls-mod>
      <!-- <room-controls :roomId="this.room.id"></room-controls> -->
    </div>
  </div>
</template>

<script>
  import SpeedBattlesApi from '../services/api/speedbattles_api'
  import RoomUsers from '../components/room_users.vue'
  import RoomControls from '../components/room_controls.vue'
  import RoomControlsMod from '../components/room_controls_mod.vue'
  import RoomChat from '../components/room_chat.vue'
  import RoomLeaderboard from '../components/room_leaderboard.vue'
  import RoomBattle from '../components/room_battle.vue'

  export default {
    components: {
      RoomUsers,
      RoomControls,
      RoomControlsMod,
      RoomChat,
      RoomLeaderboard,
      RoomBattle
    },
    props: {
      roomInit: Object,
      usersInit: Array,
      battleInit: Object,
      userInit: Object
    },
    data() {
      return {
        loaded: false,
        room: this.roomInit,
        users: this.usersInit,
        battle: this.battleInit,
        leaderboard: [],
        challengeInput: this.battleInit.challenge.slug,
        controlsType: '',
        countdownDuration: 15,
        countdown: 0,
        announcement: {
          status: 'normal',
          content: `Welcome to ${this.roomInit.name}`
        },
      }
    },
    created() {
      this.refreshRoom()
    },
    computed: {
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
      currentUserId() {
        return this.userInit.id
      },
      currentUser() {
        const currentUserIndex = this.users.findIndex((e) => e.id === this.currentUserId);

        if (currentUserIndex === -1) {
          return this.userInit
        } else {
          return this.users[currentUserIndex]
        }
      },
      currentUserIsModerator() {
        return this.currentUser.id === this.room.moderator.id
      },
      invitedUsers() {
        if (!this.battle) { return [] }
        return this.battle.players
      },
      confirmedUsers() {
        if (!this.battle) { return [] }
        return this.battle.players.filter(user => user.invite_status == 'confirmed')
      },
      // STATUSES
      roomStatus() {
        // if (this.battleStatus.lastBattleOver && !this.battleStatus.battleLoaded) {
          // return "battle-over"
        if (!this.battleStatus.battleLoaded) {
          return "peace"
        // } else if (!this.battleStatus.readyToStart) {
        //   return "preparation"
        } else if (!this.battleStatus.battleInitialized) {
          return "brink-of-war"
        } else if (!this.battleStatus.battleOngoing) {
          return "countdown"
        } else if (!this.battleStatus.lastBattleOver) {
          return "war"
        } else {
          return "peace"
        }
      },
      battleStatus() {
        // return {
        //   battleLoaded: this.battleLoaded,
        //   readyToStart: this.readyToStart,
        //   battleInitialized: this.battleInitialized,
        //   battleOngoing: this.battleOngoing,
        //   battleRecentlyOver: this.battleRecentlyOver,
        // }
        return {
          battleLoaded: this.battle !== null,
          readyToStart: this.battle !== null && this.confirmedUsers && this.confirmedUsers.length > 0,
          battleInitialized: this.battle !== null && this.battle.start_time !== null,
          battleOngoing: this.battle !== null && this.battle.start_time !== null && this.countdown === 0,
          lastBattleOver: this.lastBattleOver,
        }
      },
      // battleRecentlyOver() {
      //   return new Date(this.previousBattles[0].end_time) > new Date(Date.now() - 1000 * 60 * 3)
      // },
      // battleLoaded() {
      //   return this.battle !== null
      // },
      // readyToStart() {
      //   return this.battleLoaded && this.confirmedUsers && this.confirmedUsers.length > 0
      // },
      // battleInitialized() {
      //   return this.battleLoaded && this.battle.start_time !== null
      // },
      // battleOngoing() {
      //   return this.battleInitialized && this.countdown === 0
      // },
      previousBattles() {
        return this.room.finished_battles.sort((a, b) => {
          return new Date(b.end_time) - new Date(a.end_time)
        })
      },
      lastBattle() {
        return this.battle || this.previousBattles[0]
      },
      lastBattleOver() {
        if (this.lastBattle) return this.lastBattle.end_time !== null
      },
    },
    methods: {
      // =============
      //     ROOM
      // =============
      announce(message) {
        this.announcement = {
          status: message.status || 'normal',
          content: message.content
        }
      },
      refreshRoom() {
        SpeedBattlesApi.getRoom(this.room.id)
          .then(response => {
            this.room = response
            if (this.room.active_battle) {
              this.battle = this.room.active_battle
            } else {
              this.battle = null
            }
            this.refreshLeaderboard()
            // this.controlsType = this.currentUserIsModerator ? 'room-controls-mod' : 'room-controls'
            this.loaded = true
        })
      },
      refreshAll() {
        this.refreshUsers()
        if (this.battle) { this.refreshBattle() }
      },
      refreshLeaderboard() {
        SpeedBattlesApi.getLeaderboard(this.room.id)
          .then(response => {
            this.leaderboard = response
        })
      },
      // =============
      //     BATTLE
      // =============
      refreshBattle() {
        SpeedBattlesApi.getBattle(this.battle.id)
          .then(response => {
            this.battle = response
        })
      },
      createBattle(challenge) {
        SpeedBattlesApi.getChallenge(challenge)
          .then(response => {
            if (response != null) {
              SpeedBattlesApi.postBattle(this.room.id, response)
                .then((response) => {
                  this.refreshBattle()
                })
            } else {
              console.log("No kata found with this id/slug/url")
            }
          })
      },
      deleteBattle() {
        SpeedBattlesApi.deleteBattle(this.battle.id)
          .then(response => this.announce({content: 'Awaiting mission briefing...'}))
      },
      updateBattle(battle) {
        battle.deleted ? this.battle = null : this.battle = battle
        this.refreshUsers()
      },
      initializeBattle() {
        SpeedBattlesApi.updateBattleStatus(this.battle.id, 'start', this.countdownDuration)
          // .then(response => {
          //   this.$cable.perform({
          //       channel: 'BattleChannel',
          //       action: 'send_message',
          //       data: { content: 'start-countdown'}
          //   })
          // })
      },
      openCodeWars() {
        if (this.battle.challenge.language === null) { this.battle.challenge.language = 'ruby' }
        const challengeUrl = `${this.battle.challenge.url}/train/${this.battle.challenge.language}`
        window.open(challengeUrl)
      },
      endBattle() {
        SpeedBattlesApi.updateBattleStatus(this.battle.id, 'end')
      },
      fetchChallenges(userId) {
        SpeedBattlesApi.fetchChallenges(userId, this.battle.id)
      },
      // refreshBattleResults() {
      //   SpeedBattlesApi.getBattleResults(this.battle.id)
      // },
      startCountdown(countdown) {
        this.countdown = countdown
        const timer = setInterval(() => {
          if (this.countdown > 1) {
            this.broadcastMessage({
              author: {
                username: 'bot'
              },
              content: `Starting battle in ${this.countdown} second${ this.countdown > 1 ? 's' : '' }...`,
              created_at: Date.now
            })
            this.countdown -= 1
          } else {
            this.broadcastMessage({
              author: {
                username: 'bot'
              },
              content: `Starting battle...`,
              created_at: Date.now
            })
            this.countdown = 0
            clearInterval(timer);
            if (!this.currentUserIsModerator) this.openCodeWars();
          }
        }, 1000)
      },
      // =============
      //     USERS
      // =============
      refreshUsers() {
        SpeedBattlesApi.getRoomUsers(this.room.id)
          .then(response => {
            this.users = response
        })
      },
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
      invitation(action, userId = null) {
        SpeedBattlesApi.invitation(this.battle.id, action, userId)
      },
      broadcastMessage(message) {
        this.$cable.perform({
            channel: 'ChatChannel',
            action: 'send_message',
            data: { content: message }
        });
      }
    },
    channels: {
      BattleChannel: {
          connected() {
            console.log('WebSockets connected to BattleChannel.')
          },
          rejected() {},
          received(data) {
            if (data.perform === 'start-countdown') {
              this.startCountdown(data.data.countdown)
            } else if (data.perform === 'end-battle') {
              this.refreshRoom()
            } else if (data.perform === 'refresh-battle') {
              this.refreshBattle()
            } else {
              this.updateBattle(data)
            }
          },
          disconnected() {}
      },
      UsersChannel: {
          connected() {
            console.log('WebSockets connected to UsersChannel')
            this.refreshUsers()
          },
          rejected() {},
          received(data) {
            if (data.unsubscribed) {
              this.removeFromUsers(data)
            } else {
              this.pushToUsers(data)
            }
            this.refreshAll()
          },
          disconnected() {}
      },
      ChatChannel: {
          connected() {
          },
          rejected() {},
          received(data) {
          },
          disconnected() {}
      }
    },
    mounted () {
      this.$cable.subscribe({ channel: 'BattleChannel', room_id: this.room.id })
      this.$cable.subscribe({ channel: 'UsersChannel', room_id: this.room.id, user_id: this.currentUser.id });
      this.$cable.subscribe({ channel: 'ChatChannel', chat_id: this.room.chat_id })
      this.$root.$on('announce', (message) => this.announce(message))
      this.$root.$on('refresh-all', () => this.refreshAll())
      this.$root.$on('create-battle', (challenge) => this.createBattle(challenge))
      this.$root.$on('delete-battle', () => this.deleteBattle())
      // this.$root.$on('refresh-battle', () => this.refreshBattle())
      this.$root.$on('refresh-users', () => this.refreshUsers())
      this.$root.$on('fetch-challenges', (userId) => this.fetchChallenges(userId))
      this.$root.$on('push-user', (user) => this.pushToUsers(user))
      this.$root.$on('remove-user', (user) => this.removeFromUsers(user))
      this.$root.$on('invite-user', (userId) => this.invitation("invite", userId))
      this.$root.$on('uninvite-user', (userId) => this.invitation("uninvite", userId))
      this.$root.$on('invite-all', () => this.invitation("all"))
      this.$root.$on('invite-survivors', () => this.invitation("survivors"))
      this.$root.$on('confirm-invite', (userId) => this.invitation("confirm", userId))
      this.$root.$on('update-battle', (battle) => this.updateBattle(battle))
      this.$root.$on('initialize-battle', () => this.initializeBattle())
      this.$root.$on('start-countdown', () => this.startCountdown())
      this.$root.$on('end-battle', () => this.endBattle())
    }
  }
</script>

<style scoped>

</style>
