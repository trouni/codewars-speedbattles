<template>
  <widget :header-title="headerTitle" :loading="loading" :seek-attention="battle.stage === 1" :focus="focus">
    <div v-if="currentUserIsModerator && showNewBattleMenu" class="d-flex flex-column h-100">
      <div class="battle-options container align-items-center">
        <div :class="['form-group mb-5', { disabled: manualKataInput }]">
          <div class="d-flex justify-content-center mt-5">
            <rank-hex
              v-for="rank in [-8, -7, -6, -5, -4, -3, -2, -1]"
              :rank="rank"
              :selected="rankActive(rank)"
              :inactive="!rankActive(rank)"
              class="clickable mx-1"
              @click.native="toggleRank(rank, $event)"
              :key="rank"
            />
          </div>
        </div>
        <div class="row">
          <div class="col col-md-6">
            <div class="battle-options-item mb-4">
              <h6 class="battle-options-title no-wrap">Language
                <span
                  class="hint custom-tooltip"
                  data-tooltip="You can modify the language in the war room settings."
                ><sup>[?]</sup></span>
              </h6>
              <h5 class="m-0 text-right">{{ settings.room.codewars_langs[settings.room.languages[0]] }}</h5>
              <!-- <select v-model="kataOptions.language" class="highlight justify-content-end">
                <option v-for="(key, lang_name) in settings.room.codewars_langs" :value="lang_name" :key="key">{{ key }}</option>
              </select> -->
            </div>
            <div :class="['battle-options-item mb-4', { disabled: manualKataInput }]">
              <h6 class="battle-options-title no-wrap">Min. user votes</h6>
              <h5 class="m-0">
                <num-input class="highlight justify-content-end" :min="0" :max="9999" :step="10" v-model="kataFiltersVotes" editable />
              </h5>
            </div>
            <div :class="['battle-options-item mb-4', { disabled: manualKataInput }]">
              <h6 class="battle-options-title no-wrap">Ignore higher rank users
                <span
                  class="hint custom-tooltip"
                  :data-tooltip="`Include katas already completed by users with a Codewars rank higher than ${-Math.max(...kataFiltersRanks)} kyu.`"
                ><sup>[?]</sup></span>
              </h6>
              <std-button @click.native="kataFiltersIgnoreHigherRankUsers = !kataFiltersIgnoreHigherRankUsers">{{ kataFiltersIgnoreHigherRankUsers ? 'ON' : 'OFF' }}</std-button>
            </div>
          </div>
          <div class="col col-md-6">
            <div class="battle-options-item mb-4">
              <h6 class="battle-options-title no-wrap">Time limit</h6>
              <h5 class="m-0">
                <num-input class="highlight justify-content-end" :min="0" :max="99" :step="1" v-model="timeLimitSetter" append="min" editable />
              </h5>
            </div>
            <div :class="['battle-options-item mb-4', { disabled: manualKataInput }]">
              <h6 class="battle-options-title no-wrap">Min. satisfaction rating</h6>
              <h5 class="m-0">
                <num-input class="highlight justify-content-end" :min="0" :max="100" v-model="kataFiltersSatisfaction" editable append="%" />
              </h5>
            </div>
            <div class="battle-options-item mb-4">
              <h6 class="battle-options-title no-wrap">Auto-invite all players
                <span
                  class="hint custom-tooltip"
                  :data-tooltip="`Invite all eligible players upon creating the battle.`"
                ><sup>[?]</sup></span>
              </h6>
              <std-button @click.native="kataFiltersAutoInvite = !kataFiltersAutoInvite">{{ kataFiltersAutoInvite ? 'ON' : 'OFF' }}</std-button>
            </div>
          </div>
        </div>
      </div>
      <p v-if="!manualKataInput" class="text-center"><small>Available katas with these options: {{ settings.room.katas.count }}</small></p>
    </div>
    <div v-else-if="battle.id" class="d-flex flex-column h-100">
      <div v-if="battle.challenge" class="challenge-info w-100 mb-3">
        <p class="mb-3">
          <rank-hex :rank="battle.challenge.rank"/>
          <strong v-if="displayChallengeName" class="highlight">
            {{ battle.challenge.name }}
          </strong>
          <strong v-else class="highlight">{{ settings.room.classification }}</strong>
          <sup>
            <span v-if="userDefeated(currentUser.id)" class="badge badge-danger">Defeat</span>
            <span v-else-if="userSurvived(currentUser.id)" class="badge badge-success">Victory</span>
            <span v-else-if="findUser(currentUser.id).invite_status == 'ineligible'" class="badge badge-warning">Already completed</span>
          </sup>
        </p>
        <div class="d-flex">
          <p><small>Language:</small> <span class="highlight">{{ challengeLanguage }} </span></p>
          <p><span class="ml-1 mr-2">|</span><small>Time Limit:</small>
            <num-input
              v-if="currentUserIsModerator && battle.stage > 0"
              class="highlight justify-content-end"
              :min="battle.stage >= 3 ? timeLimitSetter : 0"
              :max="99"
              :step="1"
              v-model="timeLimitSetter"
              append="min"
              editable
            />
            <span v-else class="highlight justify-content-end" v-html="battle.time_limit === 0 ? 'No limit' : Math.round(battle.time_limit / 60) + ' min'" />
          </p>
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
            <tr v-for="(survivor, index) in survivors" :class="['animated fadeInUp', {'highlight bg-highlight': isCurrentUser(survivor.id) }]" :title="`${survivor.username} (${-survivor.codewars.overall_rank} kyu)`" :key="survivor.id">
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
                <span class="data"></span>
              </td>
              <td>
                <span class="data">{{ formatDuration((Date.parse(battle.end_time) - Date.parse(battle.start_time)) / 1000) }}</span>
              </td>
            </tr>

            <tr v-for="defeatedUser in defeated" :title="defeatedUser.username" :class="['animated fadeInUp', { '': battle.stage === 0, 'highlight-red bg-highlight': isCurrentUser(defeatedUser.id) }]" :key="defeatedUser.id">
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
    <div v-else-if="!loading" class="d-flex flex-column h-100">
      <p class="highlight">> No previous battle records...</p>
    </div>

    <template v-slot:controls>
      <div v-if="battle.stage < 3 && currentUserIsModerator" class="d-contents">
        <div v-if="manualKataInput" class="with-prompt centered-prompt w-100">
          <input
            type="text"
            class="w-100"
            @keyup.enter="createBattle"
            @keyup.escape="manualKataInput = false"
            placeholder="Enter the ID/url of the kata to load (ESC to cancel)"
            v-model="challengeInput"
            v-focus
          >
          <std-button small @click.native="createBattle" fa-icon="fas fa-cloud-upload-alt" title="Load" />
        </div>
        <span v-else-if="showNewBattleMenu" class="d-contents">
          <std-button @click.native="showNewBattleMenu = false" fa-icon="fas fa-angle-double-left" title="Cancel" />
          <std-button @click.native="manualKataInput = true" fa-icon="fas fa-file-import" title="Import Kata" />
          <std-button @click.native="createRandomBattle" fa-icon="fas fa-cloud-upload-alt" title="Load Random Kata" />
        </span>
        <span v-else-if="battle.stage === 0 && !loading && !showNewBattleMenu" class="d-contents">
          <std-button @click.native="openNewBattleMenu" fa-icon="fas fa-plus-square" title="New Battle" />
        </span>
        <span v-else-if="battle.stage > 0 && battle.stage < 3" class="d-contents">
          <std-button @click.native="$root.$emit('delete-battle')" small fa-icon="fas fa-times-circle" title="Cancel" />
          <std-button @click.native="$root.$emit('invite-survivors')" small fa-icon="fas fa-user-plus" title="Invite Survivors" :disabled="eligibleUsers.length === 0" />
          <std-button @click.native="$root.$emit('invite-all')" small fa-icon="fas fa-user-plus" title="Invite All" :disabled="eligibleUsers.length === 0" />
          <std-button v-if="battle.stage < 4" @click.native="$root.$emit('initialize-battle')" :disabled="!readyToStart" fa-icon="fas fa-radiation" title="Start Battle" :class="attentionWaitingToStart" />
        </span>
      </div>
      <div v-else-if="battle.stage >= 3" class="d-contents">
        <a :href="battle.stage < 4 ? '#' : challengeUrl" :target="battle.stage < 4 ? '' : '_blank'">
          <std-button fa-icon="fas fa-rocket mr-1" title="Launch Codewars" :disabled="battle.stage < 4" />
        </a>
        <std-button v-if="userIsConfirmed(currentUser.id)" @click.native="completedChallenge" fa-icon="fas fa-check-double mr-1" title="Challenge Completed" :disabled= "battle.stage < 4" :loading="completedButtonClicked" />
        <std-button v-if="currentUserIsModerator" @click.native="$root.$emit('end-battle')" :disabled="battle.stage < 4" fa-icon="fas fa-peace" title="End Battle" />
      </div>
    </template>
  </widget>
</template>

<script>
  import Vue from 'vue/dist/vue.esm'
  import capitalize from 'lodash/capitalize'
  import includes from 'lodash/includes'
  import debounce from "lodash/debounce";
  
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
      readyToStart: Boolean,
      loading: Boolean,
      focus: Boolean,
      settings: Object,
      katasCount: Number,
    },
    data() {
      return {
        completedButtonClicked: false,
        showNewBattleMenu: false,
        manualKataInput: false,
        challengeInput: '',
        seekAttentionClass: 'animated infinite pulse seek-attention',
        timeLimitSetter: Math.round((this.battle.time_limit || 0) / 60),
        kataFiltersRanks: Vue.util.extend([], this.settings.room.katas.ranks),
        kataFiltersVotes: this.settings.room.katas.min_votes,
        kataFiltersSatisfaction: this.settings.room.katas.min_satisfaction,
        kataFiltersIgnoreHigherRankUsers: this.settings.room.katas.ignore_higher_rank_users,
        kataFiltersAutoInvite: this.settings.room.auto_invite,
      }
    },
    watch: {
      timeLimitSetter: {
        handler: 'updateTimeLimit',
      }
    },
    computed: {
      kataOptions() {
        this.getKatasCount()
        return {
          ranks: this.kataFiltersRanks,
          min_votes: this.kataFiltersVotes,
          min_satisfaction: this.kataFiltersSatisfaction,
          language: this.settings.room.languages[0],
          ignore_higher_rank_users: this.kataFiltersIgnoreHigherRankUsers,
        }
      },
      challengeLanguage() {
        return this.settings.room.codewars_langs[this.battle.challenge.language]
      },
      attentionWaitingToJoin() {
        if (this.currentUser.invite_status === 'invited') {
          this.$root.$emit('play-fx', 'interface')
          return this.seekAttentionClass
        }
      },
      attentionWaitingToStart() {
        if (this.currentUserIsModerator && this.invitedUsers.length === 0 && this.confirmedUsers.length > 0) {
          return this.seekAttentionClass
        }
      },
      challengeUrl() {
        if (this.battle.challenge.language === null) { this.battle.challenge.language = 'ruby' }
        return `${this.battle.challenge.url}/train/${this.battle.challenge.language}`
      },
      // headerTitle() {
      //   const prefix = 'KATA://'
      //   if (this.battle.stage === 4) {
      //     return `${prefix}Battle_Report`
      //   } else if (this.battle.stage === 5) {
      //     this.$root.$emit('announce',{content: 'Battle over. Awaiting next mission...'})
      //     return `${prefix}Last_Battle_Report`
      //   } else if (this.battle.stage > 0) {
      //     this.$root.$emit('announce',{content: 'Prepare for battle...'})
      //     return `${prefix}Mission_Briefing`
      //   } else if (this.showNewBattleMenu) {
      //     return `${prefix}New_Mission`
      //   } else {
      //     return `${prefix}Awaiting_Mission`
      //   }
      // },
      headerTitle() {
        const prefix = 'KATA://'
        if (this.battle.stage > 0 && this.battle.stage < 4) {
          return `${prefix}NEXT_MISSION`
        } else if (this.battle.stage === 4) {
          return `${prefix}MISSION_IN_PROGRESS`
        } else if (this.showNewBattleMenu) {
          return `${prefix}CREATE_NEW_BATTLE`
        } else {
          return `${prefix}LAST_MISSION_REPORT`
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
      displayChallengeName() {
        return this.settings.room.classification === 'UNCLASSIFIED' ||
          (this.settings.room.classification === 'CONFIDENTIAL' && this.currentUserIsModerator) ||
          this.battle.stage === 0 ||
          this.battle.stage > 2
      },
      eligibleUsers() {
        if (this.battle.stage === 0) { return [] }
        // return this.battle.players
        return this.users.filter(user => user.invite_status === 'eligible')
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
        this.showNewBattleMenu = false
        this.manualKataInput = false
        this.$root.$emit('create-battle', {
          challenge: this.challengeInput,
          timeLimit: this.timeLimitSetter * 60,
          autoInvite: this.kataFiltersAutoInvite,
        })
        this.challengeInput = ''
        this.$root.$emit('play-fx', 'click')
      },
      createRandomBattle() {
        this.showNewBattleMenu = false
        this.$root.$emit('create-random-battle', {
          kata: this.kataOptions,
          time_limit: this.timeLimitSetter * 60,
          auto_invite: this.kataFiltersAutoInvite,
        })
        this.$root.$emit('play-fx', 'click')
      },
      getKatasCount: debounce(function() {
        this.$root.$emit('get-katas-count', this.kataOptions)
      }, 1000),
      openNewBattleMenu() {
        this.showNewBattleMenu = true
      },
      isCurrentUser(userId) {
        return this.currentUser.id === userId
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
      rankActive(rank) {
        return includes(this.kataOptions.ranks, rank)
      },
      toggleRank(rank, e) {
        // Allow multiple ranks selection with cmd, shift or ctrl
        if (e.metaKey || e.shiftKey || e.ctrlKey) {
          this.rankActive(rank) ? this.kataFiltersRanks.splice(this.kataFiltersRanks.indexOf(rank), 1) : this.kataFiltersRanks.push(rank)
        } else {
          this.kataFiltersRanks = [rank]
        }
      },
      updateTimeLimit: debounce(function() {
        if (this.battle.stage > 0) this.$root.$emit('edit-time-limit', this.timeLimitSetter)
      }, 300)
    }
  }
</script>

<style lang="scss">
  .challenge-info {
    font-size: 1.2em;
    padding: 0.5em 0.5em 0 0.5em;
  }

  .rank > i {
    line-height: inherit;
  }

  .battle-options {
    max-width: 600px;
    .col:first-child {
      border-right: solid 0.5px rgba(255,255,255,0.1)
    }
    .col {
      padding: 0 2em;
    }
  }

  .battle-options-item {
    position: relative;
    display: flex;
    align-items: center;
    min-height: 4em;
    select {
      text-align: right;
      text-align-last: right;
    }
  }

  .battle-options-title {
    margin: 0;
    flex-grow: 1;
  }
</style>
