<template>
  <div id="room-battle" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <div v-if="canShowChallenge">
      <h4>{{ battle.challenge.name }}</h4>
      <p>{{ battle.challenge.description }}</p>
    </div>
    <h4>{{ countdown }}</h4>
  </div>
</template>

<script>
  export default {
    props: {
      roomId: Number,
      battle: Object,
      countdown: Number,
      currentUserIsModerator: Boolean
    },
    data: function () {
      return {
        title: "Challenge"
      }
    },
    computed: {
      battleInitialized() {
        if (this.battle) {
          return this.battle.start_time !== null && this.battle.end_time === null
        }
      },
      battleOngoing() {
        return this.battleInitialized && this.countdown === 0
      },
      canShowChallenge() {
        if (this.battle) {
          return this.currentUserIsModerator || this.battleInitialized
        }
      }
    },
    methods: {
    }
  }
</script>

<style scoped>
</style>
