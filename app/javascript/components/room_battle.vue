<template>
  <div id="room-battle" class="widget-bg">
    <div class="widget">
      <h3 class="header">{{ headerTitle }}</h3>
      <div class="widget-body">
        <div v-if="battle.id" class="d-flex flex-column h-100">
          <div v-if="battle.challenge" class="w-100 mb-3">
            <p class="m-0"><small>{{ battlePrefix }} </small>
              <strong class="highlight"> {{ displayChallengeName ? battle.challenge.name : 'TOP SECRET' }}</strong>
            </p>
            <div class="d-flex">
              <p><small>Language:</small> <span class="highlight">{{battle.challenge.language || "Ruby"}} </span></p>
              <p><span class="mx-2">|</span><small>Difficulty:</small> <span class="highlight">{{-battle.challenge.rank}} kyu</span></p>
              <p v-if="timeLimit > 0"><span class="mx-2">|</span><small>Time limit:</small> <span class="highlight">{{("0" + timeLimit).slice(-2)}} min</span></p>
              <p v-else><span class="mx-2">|</span><small>No time limit</small></p>
            </div>
          </div>
          <p v-if="battle.stage === 1 && defeated.length < 1" class="m-auto highlight">> Waiting for players to join the battle...</p>
          <table v-else class="console-table h-100">
            <thead>
              <tr>
                <th scope="col" style="width: 50%;"><span class="data">WARRIORS {{ battle.stage > 0 && battle.players ? `[${confirmedUsers().length}/${invitedUsers().length + confirmedUsers().length}]` : ""}}</span></th>
                <th scope="col" style="width: 10%;"><span class="data">RANK</span></th>
                <th scope="col" style="width: 20%;"><span class="data">STATUS</span></th>
                <th scope="col" style="width: 20%;"><span class="data">TIME</span></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(survivor, index) in survivors" class="highlight bg-highlight animated fadeInUp" :title="survivor.username" :key="survivor.id">
                <th scope="row">
                  <span class="data username">{{ survivor.name || survivor.username }}</span>
                </th>
                <td>
                  <span class="data rank">{{ index + 1 }}</span>
                </td>
                <td>
                  <span class="data">Completed</span>
                </td>
                <td>
                  <span class="data">{{ formatDuration(completedIn(battle, survivor)) }}</span>
                </td>
              </tr>

              <tr v-if="battle.stage === 0" class="battle-over">
                <th scope="row" :class="[]">
                  <span class="data">Battle over</span>
                </th>
                <td>
                  <span class="data rank"></span>
                </td>
                <td>
                  <span class="data">End time</span>
                </td>
                <td>
                  <span class="data">{{ formatDuration((Date.parse(battle.end_time) - Date.parse(battle.start_time)) / 1000) }}</span>
                </td>
              </tr>

              <tr v-for="defeatedUser in defeated" :title="defeatedUser.username" :class="['animated fadeInUp', { 'highlight-red': battle.stage === 0 }]" :key="defeatedUser.id">
                <th scope="row" :class="['username', { pending: !userIsConfirmed(defeatedUser.id) && battle.stage > 0 && battle.stage < 3 }]">
                  <span class="data username">{{ defeatedUser.name || defeatedUser.username }}</span>
                </th>
                <td>
                  <span class="data rank">{{ battle.stage === 0 ? '' : '-' }}<i v-if="battle.stage === 0" class="fas fa-skull-crossbones"></i></span>
                </td>
                <td>
                  <span class="data">{{ battle.stage === 0 ? 'Defeated' : '-' }}</span>
                </td>
                <td>
                  <span class="data">{{ defeatedUser.completed_at ? displayCompletionTime(battle, defeatedUser) : '-' }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else>
          <p class="highlight">> No previous battle records...</p>
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
      // battle: Object,
      battle: Object,
      countdown: Number,
      currentUserIsModerator: Boolean,
      battleStatus: Object,
      viewMode: String,
      timeLimit: Number
    },
    computed: {
      challengeUrl() {
        if (this.battle.challenge.language === null) { this.battle.challenge.language = 'ruby' }
        return `${this.battle.challenge.url}/train/${this.battle.challenge.language}`
      },
      headerTitle() {
        const prefix = 'KATA://'
        if (this.battle.stage === 4) {
          return `${prefix}Battle_Report`
        } else if (this.battle.stage === 5) {
          this.$root.$emit('announce',{content: 'Battle over. Awaiting next mission...'})
          return `${prefix}Last_Battle_Report`
        } else if (this.battle.stage > 0) {
          this.$root.$emit('announce',{content: 'Prepare for battle...'})
          return `${prefix}Mission_Briefing`
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
          return (this.currentUserIsModerator || this.battle.stage > 2)
        }
      },
      survivors() {
        if (this.battle.players) {
          return this.battle.players.filter(user => this.completedOnTime(user)).sort((a,b) => {
            return (new Date(a.completed_at) - new Date(b.completed_at))
          });
        }
      },
      defeated() {
        if (this.battle.players) {
          return this.battle.players.filter(user => !this.completedOnTime(user)).sort((a,b) => {
            if (a.completed_at && b.completed_at) {
              return (new Date(a.completed_at) - new Date(b.completed_at))
            } else if (a.completed_at || b.completed_at) {
              return a.completed_at ? -1 : 1
            } else {
              return (new Date(a.invited_at) - new Date(b.invited_at))
              // return (b.invite_status || [""])[0] < (a.invite_status || [""])[0] ? 1 : -1
            }
          });
        }
      },
      battlePrefix() {
        if (this.battle.stage > 0 && this.battle.stage < 4) {
          return 'NEXT BATTLE:'
        } else if (this.battle.stage === 4) {
          return 'CHALLENGE:'
        } else {
          return 'PREVIOUS BATTLE:'
        }
      },
      displayChallengeName() {
        return (this.currentUserIsModerator && this.viewMode !== 'observer') || this.battle.stage === 0 || this.battle.stage > 2
      }
    },
    methods: {
      invitedUsers() {
        if (this.battle.stage === 0) { return [] }
        // return this.battle.players
        return this.users.filter(user => user.invite_status === 'invited')
      },
      confirmedUsers() {
        if (!this.battle.players) { return [] }
        return this.battle.players.filter(user => user.invite_status == 'confirmed');
      },
      userIsConfirmed(userId) {
        if (this.findPlayer(userId)) {
          return this.findPlayer(userId).invite_status === 'confirmed';
        }
      },
      completedOnTime(user) {
        return (user.completed_at < this.battle.end_time || !this.battle.end_time) && user.completed_at > this.battle.start_time;
      },
      findUser(userId) {
        const index = this.users.findIndex((e) => e.id === userId);
        return this.users[index]
      },
      findPlayer(userId) {
        const index = this.battle.players.findIndex((e) => e.id === userId);
        return this.battle.players[index]
      },
      findBattle(battleId) {
        const index = this.previousBattles.findIndex((e) => e.id === battleId);
        return this.previousBattles[index]
      },
      completedIn(battle, user) {
        return (new Date(user.completed_at) - new Date(battle.start_time)) / 1000 // duration in seconds
      },
      displayCompletionTime(battle, user) {
        const completedIn = this.completedIn(battle, user)
        const completedAt = new Date(user.completed_at)
        completedIn >= 0 ? this.formatDuration(completedIn) : completedAt.toDateString()
      },
      formatDuration(durationInSeconds) {
        const hours = Math.floor(durationInSeconds / 60 / 60)
        const minutes = Math.floor(durationInSeconds / 60) % 60
        const seconds = Math.floor(durationInSeconds - hours * 60 * 60 - minutes * 60)
        return `${hours > 0 ? `${String(hours).padStart(2, '0')}:` : ''}${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
      },
    }
  }
</script>

<style scoped>
</style>
