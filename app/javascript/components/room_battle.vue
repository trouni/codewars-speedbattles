<template>
  <div id="room-battle" class="widget">
    <h3 class="header">{{ headerTitle }}</h3>
    <div class="widget-body">
      <div v-if="showChallenge">
        <h4>{{ battle.challenge.name }}</h4>
        <p>{{ battle.challenge.description }}</p>
      </div>
      <div v-else-if="lastBattle">
        <table class="console-table">
          <thead>
            <th scope="col"><span class="data">WARRIOR</span></th>
            <th scope="col"><span class="data">RANK</span></th>
            <th scope="col"><span class="data">STATUS</span></th>
            <th scope="col"><span class="data">TIME</span></th>
          </thead>
          <tbody>
            <tr v-for="(result, index) in lastBattle.results.survivors">
              <th scope="row">
                <span class="data username">{{ result.username }}</span>
              </th>
              <td>
                <span class="data rank">{{ index + 1 }}</span>
              </td>
              <td>
                <span class="data">Completed</span>
              </td>
              <td>
                <span class="data">{{ formatDuration(completedIn(lastBattle, result.completed_at)) }}</span>
              </td>
            </tr>
            <tr v-for="result in lastBattle.results.not_finished">
              <th scope="row">
                <span class="data username">{{ result.username }}</span>
              </th>
              <td>
                <span class="data rank">-</span>
              </td>
              <td>
                <span class="data">{{ lastBattleOver ? 'Defeated' : 'TBC' }}</span>
              </td>
              <td>
                <span class="data">-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    props: {
      room: Object,
      users: Array,
      battle: Object,
      countdown: Number,
      currentUserIsModerator: Boolean
    },
    data() {
      return {

      }
    },
    computed: {
      headerTitle() {
        const prefix = 'KATA://'
        if (this.battleOngoing) {
          this.$root.$emit('announce',{content: 'This is a code WAAAAAAAR!!'})
          return `${prefix}Battle_Report`
        } else if (this.battleLoaded) {
          this.$root.$emit('announce',{content: 'Prepare for battle...'})
          return `${prefix}Mission_Briefing`
        } else if (this.lastBattleOver) {
          this.$root.$emit('announce',{content: 'Battle over. Awaiting next mission...'})
          return `${prefix}Last_Battle_Report`
        } else {
          return `${prefix}Awaiting_Mission`
        }
      },
      battleNotStarted() {
        if (this.battle) {
          return this.battle.start_time === null
        }
      },
      battleLoaded() {
        if (this.battle) {
          return this.battle.start_time === null
        }
      },
      battleInitialized() {
        if (this.battle) {
          return this.battle.start_time !== null && this.battle.end_time === null
        }
      },
      battleOngoing() {
        return this.battleInitialized && this.countdown === 0
      },
      lastBattleOver() {
        if (this.lastBattle) {
          return this.lastBattle.end_time !== null
        }
      },
      showChallenge() {
        if (this.battle) {
          return (this.currentUserIsModerator || this.battleInitialized) && !this.battleOngoing
        }
      },
      previousBattles() {
        return this.room.finished_battles.sort((a, b) => {
          return new Date(b.end_time) - new Date(a.end_time)
        })
      },
      lastBattle() {
        // return this.findBattle(168)
        return this.battle || this.previousBattles[0]
      }
    },
    methods: {
      findUser(userId) {
        const index = this.users.findIndex((e) => e.id === userId);
        return this.users[index]
      },
      findBattle(battleId) {
        const index = this.previousBattles.findIndex((e) => e.id === battleId);
        return this.previousBattles[index]
      },
      completedIn(battle, completed_at) {
        return (new Date(completed_at) - new Date(battle.start_time)) / 1000 // duration in seconds
      },

      formatDuration(duration) {
        const hours = Math.floor(duration / 60 / 60)
        const minutes = Math.floor(duration / 60) % 60
        const seconds = Math.floor(duration - minutes * 60)
        return `${hours > 0 ? `${String(hours).padStart(2, '0')}:` : ''}${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
      },
    }
  }
</script>

<style scoped>
</style>
