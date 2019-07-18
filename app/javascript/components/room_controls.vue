<template>
  <div id="room-controls" class="widget">
    <h3 class="highlight">{{ title }}</h3>
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
    }
  }
</script>

<style scoped>
</style>
