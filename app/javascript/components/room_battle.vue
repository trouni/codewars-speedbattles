<template>
  <div id="room-battle" class="widget-bg">
    <div class="widget">
      <h3 class="header">{{ headerTitle }}</h3>
      <div class="widget-body">


        <!-- <div v-if="battle">
          <div class="d-flex justify-content-between w-100 mb-3">
            <div>
              <p v-if="showChallenge"><strong>{{ battle.challenge.name }}</strong></p>
              <p v-else><strong>Upcoming battle</strong></p>
            </div>
            <div>
              <small>Language:</small> <span class="highlight">{{battle.challenge.language || "Ruby"}}</span>
               |
              <small>Difficulty:</small> <span class="highlight">{{-battle.challenge.rank}} kyu</span>
            </div>
          </div>
           <VueShowdown
            :markdown="lastBattle.challenge.description"
            flavor="github"
            :options="{ emoji: true }"
            class="scrollable"/>
          <p class="scrollable" v-if="showChallenge">{{ lastBattle.challenge.description }}</p>
          <p class="scrollable" v-else>The instructions for the challenge will appear here during the countdown.</p>
        </div> -->

        <div v-if="lastBattle" class="d-flex flex-column align-items-center">
          <div class="d-flex justify-content-between w-100 mb-3">
            <p><strong>{{ lastBattle.challenge.name }}</strong></p>
            <div>
              <small>Language:</small> <span class="highlight">{{lastBattle.challenge.language || "Ruby"}}</span>
               |
              <small>Difficulty:</small> <span class="highlight">{{-lastBattle.challenge.rank}} kyu</span>
            </div>
          </div>
          <table class="console-table">
            <thead class="first-row">
              <th scope="col"><span class="data">WARRIOR</span></th>
              <th scope="col" style="width: 10%;"><span class="data">RANK</span></th>
              <th scope="col" style="width: 22%;"><span class="data">STATUS</span></th>
              <th scope="col" style="width: 22%;"><span class="data">TIME</span></th>
            </thead>
            <tbody>
              <tr v-for="(result, index) in lastBattle.results.survivors" class="highlight bg-highlight">
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
                  <span class="data">{{ battleStatus.lastBattleOver ? 'Defeated' : 'TBC' }}</span>
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
  </div>
</template>

<script>
  export default {
    props: {
      room: Object,
      users: Array,
      battle: Object,
      lastBattle: Object,
      countdown: Number,
      currentUserIsModerator: Boolean,
      battleStatus: Object
    },
    data() {
      return {

      }
    },
    computed: {
      challengeUrl() {
        if (this.battle.challenge.language === null) { this.battle.challenge.language = 'ruby' }
        return `${this.battle.challenge.url}/train/${this.battle.challenge.language}`
      },
      headerTitle() {
        const prefix = 'KATA://'
        if (this.battleStatus.battleOngoing) {
          this.$root.$emit('announce',{content: `<span class="d-flex justify-content-center"><a href="${this.challengeUrl}" target="_blank" class="button large mx-auto">Launch CodeWars</a></span>`})
          return `${prefix}Battle_Report`
        } else if (this.battleStatus.battleLoaded) {
          this.$root.$emit('announce',{content: 'Prepare for battle...'})
          return `${prefix}Mission_Briefing`
        } else if (this.battleStatus.lastBattleOver) {
          this.$root.$emit('announce',{content: 'Battle over. Awaiting next mission...'})
          return `${prefix}Last_Battle_Report`
        } else {
          return `${prefix}Awaiting_Mission`
        }
      },
      previousBattles() {
        return this.room.finished_battles.sort((a, b) => {
          return new Date(b.end_time) - new Date(a.end_time)
        })
      },
      showChallenge() {
        if (this.battle) {
          return (this.currentUserIsModerator || this.battleStatus.battleInitialized) && !this.battleStatus.battleOngoing
        }
      },
    },
    methods: {
      launchCodeWars() {

      },
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
