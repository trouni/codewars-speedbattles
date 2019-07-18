<template>
  <div id="room">
    <div class="grid-item grid-header">
      <h2 class="text-center">War Room {{ room.name }}</h2>
    </div>
    <div class="grid-item grid-warriors">
      <room-users :users="room.users" v-if="loaded"></room-users>
    </div>
    <div class="grid-item grid-chat">
      <room-chat></room-chat>
    </div>
    <div class="grid-item grid-battle">
      <room-battle :active-battle="room.active_battle" v-if="loaded"></room-battle>
    </div>
    <div class="grid-item grid-leaderboard">
      <room-leaderboard></room-leaderboard>
    </div>
    <div class="grid-item grid-controls">
      <component v-bind:is="controlsType" :room="room" v-if="loaded"></component>
      <!-- <room-controls :roomId="this.room.id"></room-controls> -->
    </div>
  </div>
</template>

<script>
  import SpeedBattlesApi from '../services/api/speedbattles_api'

  export default {
    props: {
      roomInit: Object,
      currentUser: Object
    },
    data() {
      return {
        loaded: false,
        room: this.roomInit,
        controlsType: '',
        activeBattleId: ''
      }
    },
    created() {
      this.getRoom()
    },
    methods: {
      getRoom() {
        SpeedBattlesApi.getRoom(this.room.id)
          .then(response => {
            this.room = response
            if (this.room.active_battle) {
              this.activeBattleId = this.room.active_battle.id
            }
            this.controlsType = this.room.moderator.id == this.currentUser.id ? 'room-controls-mod' : 'room-controls'
            this.loaded = true
        })
      },
      createBattle(challenge) {
        SpeedBattlesApi.getChallenge(challenge)
          .then(response => {
            if (response != null) {
              SpeedBattlesApi.postBattle(this.room.id, response)
                .then(response => this.getRoom())
            } else {
              console.log("No kata found with this id/slug/url")
            }
          })
      },
      deleteBattle() {
        SpeedBattlesApi.deleteBattle(this.activeBattleId)
          .then(response => this.getRoom())
      },
      inviteUser (userId) {
        SpeedBattlesApi.postInvite(this.activeBattleId, userId)
          .then(response => this.getRoom())
      },
      uninviteUser (userId) {
        SpeedBattlesApi.deleteInvite(this.activeBattleId, userId)
          .then(response => this.getRoom() )
      },
      inviteAll() {
        SpeedBattlesApi.inviteAll(this.activeBattleId)
          .then(response => this.getRoom())
      }
    },
    mounted () {
      this.$root.$on('create-battle', (challenge) => this.createBattle(challenge))
      this.$root.$on('delete-battle', () => this.deleteBattle())
      this.$root.$on('invite-user', (userId) => this.inviteUser(userId))
      this.$root.$on('uninvite-user', (userId) => this.uninviteUser(userId))
      this.$root.$on('invite-all', () => this.inviteAll())
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
