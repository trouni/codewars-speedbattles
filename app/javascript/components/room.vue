<template>
  <div id="room">
    <div class="grid-item grid-header">
      <h2 class="text-center">War Room {{ room.name }}</h2>
    </div>
    <div class="grid-item grid-warriors">
      <room-users :propRoomUsers="room.users" v-if="loaded"></room-users>
    </div>
    <div class="grid-item grid-chat">
      <room-chat></room-chat>
    </div>
    <div class="grid-item grid-battle">
      <room-battle :propBattle="room.active_battle" v-if="loaded"></room-battle>
    </div>
    <div class="grid-item grid-leaderboard">
      <room-leaderboard></room-leaderboard>
    </div>
    <div class="grid-item grid-controls">
      <room-controls :roomId="this.room.id"></room-controls>
    </div>
  </div>
</template>

<script>
  import SpeedBattlesApi from '../services/api/speedbattles_api'

  export default {
    props: [
      "props",
      "propRoom",
      "currentUser"
    ],
    data() {
      return {
        room: this.propRoom,
        loaded: false
      }
    },
    created() {
      SpeedBattlesApi.getRoom(this.room.id)
        .then(response => {
          this.room = response
          this.loaded = true
      })
    }
  }
</script>

<style scoped>
  .grid-item {
    align-items: middle;
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
    grid-template-rows: 80px calc(55% - 80px) 45%;
    grid-template-areas:
      "header header header"
      "warriors controls battle"
      "warriors chat leaderboard"
  }
</style>
