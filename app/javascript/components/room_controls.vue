<template>
  <div id="room-controls">
    <h3 class="highlight">{{ title }}</h3>
    <form @submit.prevent="createBattle">
      <input type="text" v-model="challengeInput" placeholder="Enter the id, slug or url of a CodeWars Kata">
    </form>
  </div>
</template>

<script>
  import SpeedBattlesApi from '../services/api/speedbattles_api'
  export default {
    props: {
      roomId: {
        type: Number,
        required: true
      }
    },
    data() {
      return {
        title: "Controls",
        challengeInput: ''
      }
    },
    methods: {
      createBattle() {
        SpeedBattlesApi.getChallenge(this.challengeInput)
          .then(response => {
            if (response) {
              SpeedBattlesApi.postBattle(this.roomId, response)
                .then(response => console.log(response))
            } else {
              console.log("No kata found with this id/slug/url")
            }
          })
      }
    }
  }
</script>

<style scoped>
</style>
