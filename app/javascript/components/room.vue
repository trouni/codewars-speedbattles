<template>
  <div id="room">
    <div class="grid-item grid-header">
      <h2 class="text-center">War Room {{ room["name"] }}</h2>
    </div>
    <div class="grid-item grid-warriors">
      <room-users></room-users>
    </div>
    <div class="grid-item grid-chat">
      <room-chat></room-chat>
    </div>
    <div class="grid-item grid-challenge">
      <room-challenge></room-challenge>
    </div>
    <div class="grid-item grid-leaderboard">
      <room-leaderboard></room-leaderboard>
    </div>
    <div class="grid-item grid-controls">
      <room-controls></room-controls>
    </div>
  </div>
</template>

<script>
  import SpeedBattlesApi from '../services/api/speedbattles_api'

  export default {
    props: ["roomId"],
    data: function () {
      return {
        room: ''
      }
    },
    mounted() {
      if (localStorage.room) {
        this.room = JSON.parse(localStorage.room);
      }
    },
    created() {
      SpeedBattlesApi.getRoom(this.roomId)
        .then(response => {
          localStorage.room = JSON.stringify(response)
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
  .grid-challenge {
    grid-area: challenge;
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
      "warriors controls challenge"
      "warriors chat leaderboard"
  }
</style>
