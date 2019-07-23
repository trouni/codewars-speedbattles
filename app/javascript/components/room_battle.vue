<template>
  <div id="room-battle" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <div v-if="canShowChallenge">
      <h4>{{ battle.challenge.name }}</h4>
      <p>{{ battle.challenge.description }}</p>
    </div>
    <div v-else>
      <ol>
        <li v-for="player in lastResults">
          {{ player.username }}
          {{ formatDuration(completedIn(lastBattle, player)) }}
          {{ survived (lastBattle, player) }}
        </li>
      </ol>
    </div>
    <h4>{{ countdown }}</h4>
  </div>
</template>

<script>
  export default {
    props: {
      room: Object,
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
      },
      previousBattles() {
        return this.room.finished_battles.sort((a, b) => {
          return new Date(b.end_time) - new Date(a.end_time)
        })
      },
      lastBattle() {
        return this.previousBattles[0]
      },
      lastResults() {
        return this.lastBattle.players.sort((a, b) => {
          return new Date(a.completed_at) - new Date(b.completed_at)
        })
      }
    },
    methods: {
      completedIn(battle, player) {
        return (new Date(player.completed_at) - new Date(battle.start_time)) / 1000 // duration in seconds
      },

      formatDuration(duration) {
        const hours = Math.floor(duration / 60 / 60)
        const minutes = Math.floor(duration / 60) % 60
        const seconds = Math.floor(duration - minutes * 60)
        return `${hours > 0 ? `${String(hours).padStart(2, '0')}:` : ''}${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
      },

      survived(battle, player) {
        return (new Date(player.completed_at) < new Date(battle.end_time))
      },
    }
  }
</script>

<style scoped>
</style>
