<template>
  <div id="room">
    <div class="grid-item grid-header">
      <h2 class="text-center">War Room {{ room.name }}</h2>
    </div>
    <div class="grid-item grid-warriors">
      <room-users :users="users" :room-id="room.id" :user-id="currentUserId"></room-users>
    </div>
    <div class="grid-item grid-chat">
      <room-chat :chat-id="room.chat_id" :user-id="currentUserId" v-if="loaded"></room-chat>
    </div>
    <div class="grid-item grid-battle">
      <room-battle :active-battle="activeBattle" v-if="loaded"></room-battle>
    </div>
    <div class="grid-item grid-leaderboard">
      <room-leaderboard></room-leaderboard>
    </div>
    <div class="grid-item grid-controls">
      <component v-bind:is="controlsType" :room="room" :user-id="currentUserId" v-if="loaded"></component>
      <!-- <room-controls :roomId="this.room.id"></room-controls> -->
    </div>
  </div>
</template>

<script>
  import SpeedBattlesApi from '../services/api/speedbattles_api'

  export default {
    props: {
      roomInit: Object,
      usersInit: Array,
      currentUser: Object
    },
    data() {
      return {
        loaded: false,
        room: this.roomInit,
        users: this.usersInit,
        controlsType: '',
        activeBattle: this.roomInit.active_battle,
        currentUserId: this.currentUser.id
      }
    },
    created() {
      this.refreshRoom()
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
              this.activeBattle = this.room.active_battle
            }
            this.controlsType = this.room.moderator.id == this.currentUserId ? 'room-controls-mod' : 'room-controls'
            this.loaded = true
        })
      },
      // =============
      //     BATTLE
      // =============
      createBattle(challenge) {
        SpeedBattlesApi.getChallenge(challenge)
          .then(response => {
            if (response != null) {
              SpeedBattlesApi.postBattle(this.room.id, response)
                .then(response => this.refreshRoom())
            } else {
              console.log("No kata found with this id/slug/url")
            }
          })
      },
      deleteBattle() {
        SpeedBattlesApi.deleteBattle(this.activeBattle.id)
          .then(response => this.refreshRoom())
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
      invitation (action, userId = null) {
        // SpeedBattlesApi.postInvite(this.activeBattle.id, userId)
        SpeedBattlesApi.invitation(this.activeBattle.id, action, userId)
      }
    },
    mounted () {
      this.$root.$on('refresh-room', () => this.refreshRoom())
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
