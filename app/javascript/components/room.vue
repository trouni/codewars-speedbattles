<template>
  <div id="room" v-if="loaded">
    <div class="grid-item grid-header">
      <h2 class="text-center">War Room {{ room.name }}</h2>
    </div>
    <div class="grid-item grid-warriors">
      <room-users :users="users" :room-id="room.id" :current-user="currentUser" :current-user-is-moderator="currentUserIsModerator"></room-users>
    </div>
    <div class="grid-item grid-chat">
      <room-chat :chat-id="room.chat_id" :user-id="currentUserId"></room-chat>
    </div>
    <div class="grid-item grid-battle">
      <room-battle :battle="battle" :room-id="room.id" :countdown="countdown" :current-user-is-moderator="currentUserIsModerator"></room-battle>
    </div>
    <div class="grid-item grid-leaderboard">
      <room-leaderboard></room-leaderboard>
    </div>
    <div class="grid-item grid-controls">
      <component v-bind:is="controlsType" :room="room" :battle="battle" :users="users" :current-user="currentUser" :input="challengeInput"></component>
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
        challengeInput: 'beginner-friendly-uppercase-a-string',
        controlsType: '',
        countdownDuration: 3,
        countdown: 0
      }
    },
    created() {
      this.refreshRoom()
    },
    computed: {
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
            this.controlsType = this.currentUserIsModerator ? 'room-controls-mod' : 'room-controls'
            this.loaded = true
        })
      },
      refreshAll() {
        this.refreshUsers()
        if (this.battle) { this.refreshBattle() }
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
      startCountdown() {
        this.countdown = this.countdownDuration
        const timer = setInterval(() => {
          if (this.countdown > 1) {
            this.countdown -= 1
          } else {
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
        // SpeedBattlesApi.postInvite(this.battle.id, userId)
        SpeedBattlesApi.invitation(this.battle.id, action, userId)
      }
    },
    channels: {
      BattleChannel: {
          connected() {
            console.log('WebSockets connected to BattleChannel.')
          },
          rejected() {},
          received(data) {
            console.log(data)
            if (data.perform === 'start-countdown') {
              this.startCountdown()
            } else if (data.perform === 'end-battle') {
              this.refreshRoom()
            } else {
              this.updateBattle(data)
            }
          },
          disconnected() {}
      }
    },
    mounted () {
      this.$cable.subscribe({ channel: 'BattleChannel', room_id: this.room.id })
      this.$root.$on('refresh-all', () => this.refreshAll())
      this.$root.$on('create-battle', (challenge) => this.createBattle(challenge))
      this.$root.$on('delete-battle', () => this.deleteBattle())
      this.$root.$on('refresh-users', () => this.refreshUsers())
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
  .grid-item {
    align-items: middle;
    padding: 1em;
  }
  .grid-header {
    grid-area: header;
  }
  .grid-warriors {
    grid-area: warriors;
  }
  .grid-chat {
    grid-area: chat;
  }
  .grid-battle {
    grid-area: battle;
  }
  .grid-leaderboard {
    grid-area: leaderboard;
  }
  .grid-controls {
    grid-area: controls;
  }

  #room {
    background: radial-gradient(ellipse farthest-corner at top left, #086788CC 10%, #1B435440), linear-gradient(#00000088, #00000033)/*, asset-url('bg_codewars_3.jpg')*/;
    background-size: cover;
    height: 100vh;
    display: grid;
    grid-template-columns: 18% 41% 41%;
    grid-template-rows: 70px calc(50% - 70px) 15% 35%;
    grid-template-areas:
      "header header header"
      "warriors battle chat"
      "warriors battle leaderboard"
      "warriors controls leaderboard"
  }
</style>
