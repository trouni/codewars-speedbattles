<template>
  <widget :header-title="headerTitle" :loading="loading" :seek-attention="battle.stage === 1" :focus="focus">
    <div v-if="battle.id" class="d-flex flex-column h-100">
      <div v-if="battle.challenge" class="challenge-info w-100 mb-3">
        <p class="m-0"><small>{{ battlePrefix }} </small>
          <strong class="highlight"> {{ displayChallengeName ? battle.challenge.name : 'TOP SECRET' }}</strong>
          <sup>
            <span v-if="userDefeated(currentUser.id)" class="badge badge-danger">Defeat</span>
            <span v-else-if="userSurvived(currentUser.id)" class="badge badge-success">Victory</span>
            <span v-else-if="findUser(currentUser.id).invite_status == 'ineligible'" class="badge badge-warning">Already completed</span>
          </sup>
        </p>
        <div class="d-flex">
          <p class=""><small>Language:</small> <span class="highlight">{{battle.challenge.language || "Ruby"}} </span></p>
          <p class=""><span class="mx-2">|</span><small>Difficulty:</small> <span class="highlight">{{-battle.challenge.rank}} kyu</span></p>
          <p class=""><span class="mx-2">|</span><small>Time Limit:</small>
            <timer-selector
              class="highlight"
              :time-limit="timeLimit"
              :editable="currentUserIsModerator && battle.stage > 0 && battle.stage < 3"
            />
          </p>
          <!-- <p v-if="timeLimit > 0"><span class="mx-2">|</span><small>Time limit:</small> <span class="highlight">{{("0" + timeLimit).slice(-2)}} min</span></p>
          <p v-else><span class="mx-2">|</span><small>No time limit</small></p> -->
        </div>
      </div>
      <p v-if="battle.stage === 1 && defeated.length < 1" class="m-auto highlight">> Waiting for players to join the battle...</p>
      <div v-else-if="currentUser.invite_status == 'invited'" class="d-flex flex-column justify-content-center align-items-center flex-grow-1 mb-5">
        <p>You have been requested to join this battle.</p>
        <std-button large @click.native="$root.$emit('confirm-invite', currentUser.id)" title="Join battle" :class="['my-3', attentionWaitingToJoin]"/>
        <std-button small @click.native="$root.$emit('uninvite-user', currentUser.id)" title="Skip" />
      </div>
      <div v-else class="fixed-header">
        <table class="console-table h-100">
          <thead>
            <tr>
              <th scope="col" style="width: 50%;"><span class="data">WARRIORS {{ battle.stage > 0 && battle.players ? `[${confirmedUsers.length}/${invitedUsers.length + confirmedUsers.length}]` : ""}}</span></th>
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
    </div>
    <div v-else class="d-flex flex-column h-100">
      <p class="highlight">> No previous battle records...</p>
    </div>

    <div v-if="!createNewBattle">
      <div v-if="battle.stage === 0 && currentUserIsModerator" class="ui-controls-bottom">
        <std-button small v-if="!createNewBattle" @click.native="createNewBattle = true" fa-icon="fas fa-plus" title="New Battle" class="ml-auto" />
      </div>
      <div v-else-if="battle.stage > 0 && battle.stage < 3 && currentUserIsModerator" class="ui-controls-bottom">
        <std-button @click.native="$root.$emit('delete-battle')" small fa-icon="fas fa-times-circle" title="Cancel" />
        <std-button @click.native="$root.$emit('invite-survivors')" small fa-icon="fas fa-user-plus" title="Invite Survivors" />
        <std-button @click.native="$root.$emit('invite-all')" small fa-icon="fas fa-user-plus" title="Invite All" />
        <std-button v-if="battle.stage < 4" @click.native="$root.$emit('initialize-battle')" :disabled="!readyToStart" fa-icon="fas fa-radiation" title="Start Battle" :class="attentionWaitingToStart" />
      </div>
      <div v-else-if="battle.stage >= 3" class="ui-controls-bottom">
        <a :href="battle.stage < 4 ? '#' : challengeUrl" :target="battle.stage < 4 ? '' : '_blank'">
          <std-button fa-icon="fas fa-rocket mr-1" title="Launch Codewars" :disabled="battle.stage < 4" />
        </a>
        <std-button v-if="userIsConfirmed(currentUser.id)" @click.native="completedChallenge" fa-icon="fas fa-check-double mr-1" title="Challenge Completed" :disabled= "battle.stage < 4" :loading="completedButtonClicked" />
        <std-button v-if="currentUserIsModerator" @click.native="$root.$emit('end-battle')" :disabled="battle.stage < 4" fa-icon="fas fa-peace" title="End Battle" />
      </div>
    </div>
    <div v-else class="ui-controls-bottom">
      <span class="input-with-prompt w-100">
        <input
          type="text"
          class="w-100"
          @keyup.enter="createBattle"
          @keyup.escape="createNewBattle = false"
          placeholder="Enter the ID, slug or url of the kata (ESC to cancel)"
          v-model="challengeInput"
          v-focus
        >
      </span>
      <!-- <std-button @click.native="createBattle" :disabled="!challengeInput" fa-icon="fas fa-cloud-upload-alt" title="Load" /> -->
    </div>
  </widget>
</template>

<script>
  export default {
    props: {
      initializing: Boolean,
      roomStatus: String,
      room: Object,
      users: Array,
      battle: Object,
      countdown: Number,
      currentUser: Object,
      currentUserIsModerator: Boolean,
      battleStatus: Object,
      viewMode: String,
      timeLimit: Number,
      readyToStart: Boolean,
      loading: Boolean,
      focus: Boolean,
    },
    components: {
      TimerSelector: () => import('./battle/timer_selector'),
    },
    data() {
      return {
        completedButtonClicked: false,
        createNewBattle: false,
        challengeInput: '',
        seekAttentionClass: 'animated infinite pulse seek-attention',
      }
    },
    computed: {
      attentionWaitingToJoin() {
        if (this.currentUser.invite_status === 'invited') {
          this.$root.$emit('play-fx', 'interface')
          return this.seekAttentionClass
        }
      },
      attentionWaitingToStart() {
        if (this.currentUserIsModerator && this.invitedUsers.length === 0 && this.confirmedUsers.length > 0) {
          this.$root.$emit('play-fx', 'interface')
          return this.seekAttentionClass
        }
      },
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
        } else if (this.createNewBattle) {
          return `${prefix}New_Mission`
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
          return 'LAST BATTLE:'
        }
      },
      displayChallengeName() {
        return (this.currentUserIsModerator && this.viewMode !== 'observer') || this.battle.stage === 0 || this.battle.stage > 2
      },
      invitedUsers() {
        if (this.battle.stage === 0) { return [] }
        // return this.battle.players
        return this.users.filter(user => user.invite_status === 'invited')
      },
      confirmedUsers() {
        if (!this.battle.players) { return [] }
        return this.battle.players.filter(user => user.invite_status == 'confirmed');
      },
    },
    methods: {
      createBattle() {
        this.createNewBattle = false
        this.$root.$emit('create-battle', this.challengeInput)
        this.challengeInput = ''
        this.$root.$emit('play-fx', 'click')
      },
      userIsPlayer(userId) {
        return !!this.findPlayer(userId)
      },
      userIsConfirmed(userId) {
        if (this.findPlayer(userId)) {
          return this.findPlayer(userId).invite_status === 'confirmed';
        }
      },
      userSurvived(userId) {
        if (this.findPlayer(userId)) {
          return this.findPlayer(userId).invite_status === 'survived';
        }
      },
      userDefeated(userId) {
        if (this.findPlayer(userId)) {
          return this.findPlayer(userId).invite_status === 'defeated';
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
        return completedIn >= 0 ? this.formatDuration(completedIn) : completedAt.toLocaleDateString()
      },
      formatDuration(durationInSeconds) {
        const hours = Math.floor(durationInSeconds / 60 / 60)
        const minutes = Math.floor(durationInSeconds / 60) % 60
        const seconds = Math.floor(durationInSeconds - hours * 60 * 60 - minutes * 60)
        return `${hours > 0 ? `${String(hours).padStart(2, '0')}:` : ''}${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
      },
      completedChallenge() {
        this.completedButtonClicked = true;
        setTimeout(() => {
          this.completedButtonClicked = false;
        }, 3000)
        this.$root.$emit('fetch-challenges');
      },
    }
  }
</script>

<style scoped>
  .challenge-info {
    font-size: 1.1rem;
    padding: 1em 0.5em;
  }

  .rank > i {
    line-height: inherit;
  }
</style>
