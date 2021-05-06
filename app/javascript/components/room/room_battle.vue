<template>
  <widget
    :header-title="headerTitle"
    :loading="loading"
    :seek-attention="battleStage > 0 && battleStage < 3"
    :focus="focus"
  >
    <div
      v-if="currentUserIsModerator && showNewBattleMenu"
      class="d-flex flex-column h-100"
    >
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
              <h6 class="battle-options-title no-wrap">
                Language
                <span
                  class="hint custom-tooltip"
                  data-tooltip="You can modify the language in the war room settings."
                  ><sup>[?]</sup></span
                >
              </h6>
              <h5 class="m-0 text-right">
                {{ settings.room.codewars_langs[settings.room.languages[0]] }}
              </h5>
              <!-- <select v-model="kataOptions.language" class="highlight justify-content-end">
                <option v-for="(key, lang_name) in settings.room.codewars_langs" :value="lang_name" :key="key">{{ key }}</option>
              </select> -->
            </div>
            <div
              :class="[
                'battle-options-item mb-4',
                { disabled: manualKataInput }
              ]"
            >
              <h6 class="battle-options-title no-wrap">Min. user votes</h6>
              <h5 class="m-0">
                <num-input
                  class="highlight justify-content-end"
                  :min="0"
                  :max="9999"
                  :step="10"
                  v-model="kataFiltersVotes"
                  editable
                />
              </h5>
            </div>
            <div
              :class="[
                'battle-options-item mb-4',
                { disabled: manualKataInput }
              ]"
            >
              <h6 class="battle-options-title no-wrap">
                Ignore higher rank users
                <span
                  class="hint custom-tooltip"
                  :data-tooltip="
                    `Include katas already completed by users with a Codewars rank higher than ${-Math.max(
                      ...kataFiltersRanks
                    )} kyu.`
                  "
                  ><sup>[?]</sup></span
                >
              </h6>
              <std-button
                @click.native="
                  kataFiltersIgnoreHigherRankUsers = !kataFiltersIgnoreHigherRankUsers
                "
                >{{
                  kataFiltersIgnoreHigherRankUsers ? "ON" : "OFF"
                }}</std-button
              >
            </div>
          </div>
          <div class="col col-md-6">
            <div class="battle-options-item mb-4">
              <h6 class="battle-options-title no-wrap">Time limit</h6>
              <h5 class="m-0">
                <num-input
                  class="highlight justify-content-end"
                  :min="0"
                  :max="99"
                  :step="1"
                  v-model="timeLimitSetter"
                  append="min"
                  editable
                />
              </h5>
            </div>
            <div
              :class="[
                'battle-options-item mb-4',
                { disabled: manualKataInput }
              ]"
            >
              <h6 class="battle-options-title no-wrap">
                Min. satisfaction rating
              </h6>
              <h5 class="m-0">
                <num-input
                  class="highlight justify-content-end"
                  :min="0"
                  :max="100"
                  v-model="kataFiltersSatisfaction"
                  editable
                  append="%"
                />
              </h5>
            </div>
            <div class="battle-options-item mb-4">
              <h6 class="battle-options-title no-wrap">
                Auto-invite all players
                <span
                  class="hint custom-tooltip"
                  :data-tooltip="
                    `Invite all eligible players upon creating the battle.`
                  "
                  ><sup>[?]</sup></span
                >
              </h6>
              <std-button
                @click.native="kataFiltersAutoInvite = !kataFiltersAutoInvite"
                >{{ kataFiltersAutoInvite ? "ON" : "OFF" }}</std-button
              >
            </div>
          </div>
        </div>
      </div>
      <p v-if="!manualKataInput" class="text-center">
        <small
          >Available katas with these options:
          {{ settings.room.katas.count }}</small
        >
      </p>
    </div>
    <div v-else-if="battle.id" class="d-flex flex-column h-100">
      <div v-if="battle.challenge" class="challenge-info w-100 mb-3">
        <p class="mb-3">
          <rank-hex :rank="battle.challenge.rank" />
          <strong v-if="displayChallengeName" class="highlight">
            {{ battle.challenge.name }}
          </strong>
          <strong v-else class="highlight">{{
            settings.room.classification
          }}</strong>
          <sup>
            <span v-if="userDefeated(currentUser.id)" class="badge badge-danger"
              >Defeat</span
            >
            <span
              v-else-if="userSurvived(currentUser.id)"
              class="badge badge-success"
              >Victory</span
            >
            <span
              v-else-if="findUser(currentUser.id).invite_status == 'ineligible'"
              class="badge badge-warning"
              >Already completed</span
            >
          </sup>
        </p>
        <div class="d-flex">
          <p>
            <small>Language:</small>
            <span class="highlight">{{ challengeLanguage }}</span>
          </p>
          <p>
            <span class="mx-2">|</span><small>Time Limit:</small>
            <num-input
              v-if="currentUserIsModerator && battleStage > 0"
              class="highlight justify-content-end"
              :min="battleStage > 3 ? timeLimitSetter : 0"
              :max="99"
              :step="1"
              v-model="timeLimitSetter"
              append="min"
              editable
            />
            <span
              v-else
              class="highlight justify-content-end"
              v-html="
                battle.time_limit === 0
                  ? 'No limit'
                  : Math.round(battle.time_limit / 60) + ' min'
              "
            />
          </p>
        </div>
      </div>
      <p
        v-if="
          battleStage === 1 && invitedUsers.length + confirmedUsers.length < 1
        "
        class="m-auto highlight"
      >
        > Waiting for players to join the battle...
      </p>
      <div v-else class="d-contents">
        <div
          v-if="currentUser.invite_status == 'invited' && battleJoinable"
          class="widget-message-box w-100"
        >
          <p>You have been invited to this battle.</p>
          <std-button
            large
            @click.native="$root.$emit('confirm-invite', currentUser.id)"
            title="Join battle"
            :class="['my-3', attentionWaitingToJoin]"
          />
          <std-button
            small
            @click.native="$root.$emit('uninvite-user', currentUser.id)"
            title="Skip"
          />
        </div>
        <div class="fixed-header">
          <table class="console-table h-100">
            <thead>
              <tr>
                <th scope="col" style="width: 50%;">
                  <span class="data"
                    >WARRIORS
                    {{
                      battleStage > 0 && users
                        ? `[${confirmedUsers.length}/${invitedUsers.length +
                            confirmedUsers.length}]`
                        : ""
                    }}</span
                  >
                </th>
                <th scope="col" style="width: 10%;">
                  <span class="data">RANK</span>
                </th>
                <th scope="col" style="width: 20%;">
                  <span class="data">STATUS</span>
                </th>
                <th scope="col" style="width: 20%;">
                  <span class="data">TIME</span>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(survivor, index) in survivors"
                :class="[
                  'animated fadeInUp',
                  { 'highlight bg-highlight': isCurrentUser(survivor.id) }
                ]"
                :title="
                  `${
                    survivor.username
                  } (${-survivor.codewars_overall_rank} kyu)`
                "
                :key="survivor.id"
              >
                <th scope="row">
                  <span class="data username">{{
                    survivor.name || survivor.username
                  }}</span>
                </th>
                <td>
                  <span class="data rank">{{ index + 1 }}</span>
                </td>
                <td>
                  <span class="data">Completed</span>
                </td>
                <td>
                  <span class="data">{{
                    formatDuration(completedIn(battle, survivor))
                  }}</span>
                </td>
              </tr>

              <tr v-if="battleStage === 0" class="battle-over">
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
                  <span class="data">{{
                    formatDuration(
                      (Date.parse(battle.end_time) -
                        Date.parse(battle.start_time)) /
                        1000
                    )
                  }}</span>
                </td>
              </tr>

              <tr
                v-for="defeatedUser in defeated"
                :title="defeatedUser.username"
                :class="[
                  'animated fadeInUp',
                  {
                    '': battleStage === 0,
                    'highlight-red bg-highlight': isCurrentUser(defeatedUser.id)
                  }
                ]"
                :key="defeatedUser.id"
              >
                <th
                  scope="row"
                  :class="[
                    'username',
                    {
                      pending:
                        !userIsConfirmed(defeatedUser.id) && battleJoinable
                    }
                  ]"
                >
                  <span class="data username">{{
                    defeatedUser.name || defeatedUser.username
                  }}</span>
                </th>
                <td>
                  <span class="data rank"
                    >{{ battleStage === 0 ? "" : "-"
                    }}<i
                      v-if="battleStage === 0"
                      class="fas fa-skull-crossbones"
                    ></i
                  ></span>
                </td>
                <td>
                  <span class="data">{{
                    battleStage === 0 ? "Defeated" : "-"
                  }}</span>
                </td>
                <td>
                  <span class="data">{{
                    defeatedUser.completed_at
                      ? displayCompletionTime(battle, defeatedUser)
                      : "-"
                  }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <div v-else-if="!loading" class="d-flex flex-column h-100">
      <p class="highlight">> No previous battle records...</p>
    </div>

    <template v-slot:controls>
      <div v-if="battleStage < 3 && currentUserIsModerator" class="d-contents">
        <div v-if="manualKataInput" class="with-prompt centered-prompt w-100">
          <input
            type="text"
            class="w-100"
            @keyup.enter="createBattle"
            @keyup.escape="manualKataInput = false"
            placeholder="Enter the ID/url of the kata to load (ESC to cancel)"
            v-model="challengeInput"
            v-focus
          />
          <std-button
            small
            @click.native="createBattle"
            fa-icon="fas fa-cloud-upload-alt"
            title="Load"
          />
        </div>
        <span v-else-if="showNewBattleMenu" class="d-contents">
          <std-button
            @click.native="showNewBattleMenu = false"
            fa-icon="fas fa-angle-double-left"
            title="Cancel"
          />
          <std-button
            @click.native="manualKataInput = true"
            fa-icon="fas fa-file-import"
            title="Import Kata"
          />
          <std-button
            @click.native="createRandomBattle"
            fa-icon="fas fa-cloud-upload-alt"
            title="Load Random Kata"
          />
        </span>
        <span
          v-else-if="battleStage === 0 && !loading && !showNewBattleMenu"
          class="d-contents"
        >
          <std-button
            @click.native="openNewBattleMenu"
            fa-icon="fas fa-plus-square"
            title="New Battle"
          />
        </span>
        <span v-else-if="battleStage > 0 && battleStage < 3" class="d-contents">
          <std-button
            @click.native="$root.$emit('delete-battle')"
            small
            fa-icon="fas fa-times-circle"
            title="Cancel"
          />
          <std-button
            @click.native="$root.$emit('invite-survivors')"
            small
            fa-icon="fas fa-user-plus"
            title="Invite Survivors"
            :disabled="eligibleUsers.length === 0"
          />
          <std-button
            @click.native="$root.$emit('invite-all')"
            small
            fa-icon="fas fa-user-plus"
            title="Invite All"
            :disabled="eligibleUsers.length === 0"
          />
          <std-button
            v-if="battleStage < 4"
            @click.native="$root.$emit('initialize-battle')"
            :disabled="!readyToStart"
            fa-icon="fas fa-radiation"
            title="Start Battle"
            :class="attentionWaitingToStart"
          />
        </span>
      </div>
      <div v-else-if="battleStage >= 3" class="d-contents">
        <std-button
          @click.native="$root.$emit('open-codewars', true)"
          fa-icon="fas fa-rocket mr-1"
          title="Launch Codewars"
          :disabled="battleStage < 4"
        />
        <std-button
          v-if="userIsConfirmed(currentUser.id)"
          @click.native="completedChallenge"
          fa-icon="fas fa-check-double mr-1"
          title="Challenge Completed"
          :disabled="battleStage < 4"
          :loading="completedButtonClicked"
        />
        <std-button
          v-if="currentUserIsModerator"
          @click.native="$root.$emit('end-battle')"
          :disabled="battleStage < 4"
          fa-icon="fas fa-peace"
          title="End Battle"
        />
      </div>
    </template>
  </widget>
</template>

<script>
import Vue from "vue/dist/vue.esm";
import capitalize from "lodash/capitalize";
import includes from "lodash/includes";
import debounce from "lodash/debounce";

export default {
  props: {
    initializing: Boolean,
    room: Object,
    users: Array,
    battle: Object,
    battleStage: Number,
    countdown: Number,
    currentUser: Object,
    currentUserIsModerator: Boolean,
    battleJoinable: Boolean,
    readyToStart: Boolean,
    loading: Boolean,
    focus: Boolean,
    settings: Object,
    katasCount: Number
  },
  data() {
    return {
      completedButtonClicked: false,
      showNewBattleMenu: false,
      manualKataInput: false,
      challengeInput: "",
      seekAttentionClass: "animated infinite pulse seek-attention",
      timeLimitSetter: Math.round((this.battle.time_limit || 0) / 60),
      kataFiltersRanks: Vue.util.extend([], this.settings.room.katas.ranks),
      kataFiltersVotes: this.settings.room.katas.min_votes,
      kataFiltersSatisfaction: this.settings.room.katas.min_satisfaction,
      kataFiltersIgnoreHigherRankUsers: this.settings.room.katas
        .ignore_higher_rank_users,
      kataFiltersAutoInvite: this.settings.room.auto_invite
    };
  },
  watch: {
    timeLimitSetter: {
      handler: "updateTimeLimit"
    },
    currentUser: {
      handler(newVal, oldVal) {
        if (newVal && newVal.invite_status !== "invited") return;

        if (!oldVal || oldVal.invite_status !== newVal.invite_status)
          this.$root.$emit("play-fx", "interface");
      },
      deep: true,
      immediate: true
    }
  },
  computed: {
    kataOptions() {
      this.getKatasCount();
      return {
        ranks: this.kataFiltersRanks,
        min_votes: this.kataFiltersVotes,
        min_satisfaction: this.kataFiltersSatisfaction,
        language: this.settings.room.languages[0],
        ignore_higher_rank_users: this.kataFiltersIgnoreHigherRankUsers
      };
    },
    challengeLanguage() {
      if (
        this.battle.challenge.languages.includes(this.settings.user.hljs_lang)
      ) {
        return this.settings.room.codewars_langs[this.settings.user.hljs_lang];
      } else {
        return this.settings.room.codewars_langs[
          this.battle.challenge.language
        ];
      }
    },
    attentionWaitingToJoin() {
      if (this.currentUser.invite_status === "invited") {
        return this.seekAttentionClass;
      }
    },
    attentionWaitingToStart() {
      if (
        this.currentUserIsModerator &&
        this.invitedUsers.length === 0 &&
        this.confirmedUsers.length >= this.battle.min_players
      ) {
        return this.seekAttentionClass;
      }
    },
    challengeUrl() {
      if (this.battle.challenge.language === null) {
        this.battle.challenge.language = "ruby";
      }
      return `${this.battle.challenge.url}/train/${this.battle.challenge.language}`;
    },
    headerTitle() {
      const prefix = "KATA://";
      if (this.battleStage > 0 && this.battleStage < 4) {
        return `${prefix}NEXT_MISSION`;
      } else if (this.battleStage >= 4) {
        return `${prefix}MISSION_IN_PROGRESS`;
      } else if (this.showNewBattleMenu) {
        return `${prefix}CREATE_NEW_BATTLE`;
      } else {
        return `${prefix}LAST_MISSION_REPORT`;
      }
    },
    previousBattles() {
      return this.room.finished_battles.sort((a, b) => {
        return b.end_time - a.end_time;
      });
    },
    showChallenge() {
      if (this.battle) {
        return this.currentUserIsModerator || this.battleStage > 2;
      }
    },
    survivors() {
      if (this.users) {
        return this.users
          .filter(user => this.completedOnTime(user))
          .sort((a, b) => {
            return a.completed_at - b.completed_at;
          });
      }
    },
    defeated() {
      if (this.users) {
        return this.users
          .filter(
            user =>
              (this.battleJoinable && user.invite_status === "invited") ||
              user.invite_status === "confirmed" ||
              user.invite_status === "defeated"
          )
          .filter(user => !this.completedOnTime(user))
          .sort((a, b) => {
            if (a.completed_at && b.completed_at) {
              return a.completed_at - b.completed_at;
            } else if (a.completed_at || b.completed_at) {
              return a.completed_at ? -1 : 1;
            } else {
              return a.joined_battle_at - b.joined_battle_at;
              // return (b.invite_status || [""])[0] < (a.invite_status || [""])[0] ? 1 : -1
            }
          });
      }
    },
    displayChallengeName() {
      return (
        this.settings.room.classification === "UNCLASSIFIED" ||
        (this.settings.room.classification === "CONFIDENTIAL" &&
          this.currentUserIsModerator) ||
        this.battleStage === 0 ||
        (this.battleStage > 2 && !this.battleJoinable)
      );
    },
    eligibleUsers() {
      if (this.battleStage === 0) {
        return [];
      }
      // return this.users
      return this.users.filter(user => user.invite_status === "eligible");
    },
    invitedUsers() {
      if (this.battleStage === 0) {
        return [];
      }
      // return this.users
      return this.users.filter(user => user.invite_status === "invited");
    },
    confirmedUsers() {
      if (!this.users) {
        return [];
      }
      return this.users.filter(user => user.invite_status == "confirmed");
    }
  },
  methods: {
    createBattle() {
      this.showNewBattleMenu = false;
      this.manualKataInput = false;
      this.$root.$emit("create-battle", {
        challenge: this.challengeInput,
        timeLimit: this.timeLimitSetter * 60,
        autoInvite: this.kataFiltersAutoInvite
      });
      this.challengeInput = "";
      this.$root.$emit("play-fx", "click");
    },
    createRandomBattle() {
      this.showNewBattleMenu = false;
      this.$root.$emit("create-random-battle", {
        kata: this.kataOptions,
        time_limit: this.timeLimitSetter * 60,
        auto_invite: this.kataFiltersAutoInvite
      });
      this.$root.$emit("play-fx", "click");
    },
    getKatasCount: debounce(function() {
      this.$root.$emit("get-katas-count", this.kataOptions);
    }, 1000),
    openNewBattleMenu() {
      this.showNewBattleMenu = true;
    },
    isCurrentUser(userId) {
      return this.currentUser.id === userId;
    },
    userIsPlayer(userId) {
      return !!this.findUser(userId);
    },
    userIsConfirmed(userId) {
      if (this.findUser(userId)) {
        return this.findUser(userId).invite_status === "confirmed";
      }
    },
    userSurvived(userId) {
      if (this.findUser(userId)) {
        return this.findUser(userId).invite_status === "survived";
      }
    },
    userDefeated(userId) {
      if (this.findUser(userId)) {
        return this.findUser(userId).invite_status === "defeated";
      }
    },
    completedOnTime(user) {
      return (
        (user.completed_at < this.battle.end_time || !this.battle.end_time) &&
        user.completed_at > this.battle.start_time
      );
    },
    findUser(userId) {
      // Spectator
      if (userId === 0) return this.currentUser;

      const index = this.users.findIndex(e => e.id === userId);
      return this.users[index];
    },
    findBattle(battleId) {
      const index = this.previousBattles.findIndex(e => e.id === battleId);
      return this.previousBattles[index];
    },
    completedIn(battle, user) {
      return (user.completed_at - battle.start_time) / 1000; // duration in seconds
    },
    displayCompletionTime(battle, user) {
      const completedIn = this.completedIn(battle, user);
      // const completedAt = user.completed_at
      // return completedIn >= 0 ? this.formatDuration(completedIn) : completedAt.toLocaleDateString()
      return this.formatDuration(completedIn);
    },
    formatDuration(durationInSeconds) {
      const hours = Math.floor(durationInSeconds / 60 / 60);
      const minutes = Math.floor(durationInSeconds / 60) % 60;
      const seconds = Math.floor(
        durationInSeconds - hours * 60 * 60 - minutes * 60
      );
      return `${hours > 0 ? `${String(hours).padStart(2, "0")}:` : ""}${String(
        minutes
      ).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
    },
    completedChallenge() {
      this.completedButtonClicked = true;
      setTimeout(() => {
        this.completedButtonClicked = false;
      }, 3000);
      this.$root.$emit("fetch-challenges");
    },
    rankActive(rank) {
      return includes(this.kataOptions.ranks, rank);
    },
    toggleRank(rank, e) {
      // Allow multiple ranks selection with cmd, shift or ctrl
      if (e.metaKey || e.shiftKey || e.ctrlKey) {
        this.rankActive(rank)
          ? this.kataFiltersRanks.splice(this.kataFiltersRanks.indexOf(rank), 1)
          : this.kataFiltersRanks.push(rank);
      } else {
        this.kataFiltersRanks = [rank];
      }
    },
    updateTimeLimit: debounce(function() {
      if (this.battleStage > 0)
        this.$root.$emit("edit-time-limit", this.timeLimitSetter);
    }, 300)
  }
};
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
    border-right: solid 0.5px rgba(255, 255, 255, 0.1);
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
