<template>
  <div id="room" v-if="loaded" :class="{ moderator: this.currentUserIsModerator }">
    <div class="grid-item grid-header widget-bg">
      <div class="widget">
        <h3 class="header highlight">PWD://War_Room/{{ room.name }}</h3>
        <div class="widget-body position-relative">
          <span class="flash absolute-centering">
            {{ flash }}
          </span>
        </div>
      </div>
    </div>
    <!-- <div class="grid-item grid-warriors widget-bg">
      <room-users :users="users" :room-id="room.id" :current-user="currentUser" :current-user-is-moderator="currentUserIsModerator"></room-users>
    </div> -->
    <div class="grid-item grid-chat widget-bg">
      <room-chat :chat-id="room.chat_id" :user-id="currentUserId"></room-chat>
    </div>
    <div class="grid-item grid-battle widget-bg">
      <room-battle :battle="battle" :users="users" :room="room" :countdown="countdown" :current-user-is-moderator="currentUserIsModerator"></room-battle>
    </div>
    <div class="grid-item grid-leaderboard widget-bg">
      <room-leaderboard :leaderboard="leaderboard" :users="users" :room="room" :current-user="currentUser" :current-user-is-moderator="currentUserIsModerator"></room-leaderboard>
    </div>
    <div class="grid-item grid-controls widget-bg">
      <room-controls-mod :room="room" :battle="battle" :users="users" :current-user="currentUser" :input="challengeInput" :current-user-is-moderator="currentUserIsModerator" :countdown="countdown"></room-controls-mod>
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
        challengeInput: 'deodorant-evaporator',
        controlsType: '',
        countdownDuration: 2,
        countdown: 0
      }
    },
    created() {
      this.refreshRoom()
    },
    computed: {
      flash() {
        if (this.countdown > 0) {
          return `Battle starting in ${this.countdown} second${this.countdown > 1 ? 's' : ''}...`
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
      }
    },
    methods: {
      // =============
      //     ROOM
      // =============
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
                  this.challengeInput = null
                })
            } else {
              console.log("No kata found with this id/slug/url")
            }
          })
      },
      deleteBattle() {
        SpeedBattlesApi.deleteBattle(this.battle.id)
          // .then(response => this.refreshRoom())
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
      startBattle() {
        if (this.battle.challenge.language === null) { this.battle.challenge.language = 'ruby' }
        window.open(`${this.battle.challenge.url}/train/${this.battle.challenge.language}`)
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
            this.startBattle()
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
#room {
  padding: 1em;
}
</style>
