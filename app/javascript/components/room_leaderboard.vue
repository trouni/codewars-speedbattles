<template>
  <div id="room-leaderboard" class="widget">
    <h3 class="highlight">{{ title }}</h3>

    <table>
      <thead>
        <th scope="col">Player</th>
        <th scope="col">Score</th>
        <th scope="col">Total Battles</th>
        <th scope="col">Completed (Victories)</th>
        <th scope="col">Defeats</th>
      </thead>
      <tbody>
        <tr v-for="player in sortedLeaderboard">
          <th scope="row">{{ player.username }}</th>
          <td>{{ player.total_score }}</td>
          <td>{{ player.battles_fought }}</td>
          <td>{{ player.battles_survived }} ({{ player.victories }})</td>
          <td>{{ defeats(player) }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
export default {
  props: {
    leaderboard: Array
  },
  data() {
    return {
      title: "Leaderboard"
    }
  },
  computed: {
    sortedLeaderboard() {
      return this.leaderboard.sort((a, b) => {
        if (b.total_score - a.total_score !== 0) {
          return b.total_score - a.total_score
        } else {
          if (b.victories - a.victories !== 0) {
            return b.victories - a.victories
          } else {
            if (b.battles_survived - a.battles_survived !== 0) {
              return b.battles_survived - a.battles_survived
            } else {
              if (this.defeats(a) - this.defeats(b) !== 0) {
                return this.defeats(a) - this.defeats(b)
              }
            }
          }
        }
      })
    }
  },
  methods: {
    defeats(player) {
      return player.battles_fought - player.battles_survived
    }
  }
}
</script>

<style scoped>
</style>
