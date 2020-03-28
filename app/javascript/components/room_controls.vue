<template>
  <div id="room-controls" :class="['widget-bg', seekAttention]" @mouseover="attentionHover = true" @mouseleave="attentionHover = false">
    <div class="widget">
      <h3 class="header highlight">{{ title }}</h3>
      <div class="widget-body">
        <div v-if="currentUserIsModerator" class="h-100 d-flex flex-column">

          <div class="new-battle d-flex flex-column h-100">
            <input class="input-field w-100" type="text" v-model="challengeInput" @keyup.enter="createBattle" placeholder="ID, slug or url of Codewars Kata" :disabled="battle.stage > 0">
            <std-button large @click.native="createBattle" class="line-height-1 mt-4 mx-auto" v-if="battle.stage < 1" fa-icon="fas fa-cloud-upload-alt" title="Load" />

            <div class="battle-settings d-flex flex-column flex-grow-1 pb-3" v-if="battle.stage > 0 && battle.stage < 3">

              <div class="d-flex justify-content-between mt-1 line-height-1 flex-grow-1 align-items-stretch flex-grow-1">
                <div class='d-flex justify-content-center align-items-center'>
                  <h6 class="m-0"><strong>Time Limit:</strong><br/></h6>
                  <div class="timer-input text-center ml-3">
                    <h4 @click="editTimeLimit(1)" class="timer-arrow">&#9650;</h4>
                    <p v-if="timeLimit > 0" class="m-1 settings-timer">{{("0" + timeLimit).slice(-2)}}</p>
                    <p v-else class="m-1">none</p>
                    <h4 @click="editTimeLimit(-1)" :class="['timer-arrow', { disabled: timeLimit <= 0 }]">&#9660;</h4>
                  </div>
                  <span v-if="timeLimit > 0">min</span>
                </div>
                <div class="d-flex flex-column justify-content-around align-items-end">
                  <std-button @click.native="cancelBattle" fa-icon="far fa-times-circle" title="Cancel" />
                  <std-button @click.native="$root.$emit('invite-all')" :disabled="allInvited" fa-icon="fas fa-user-plus" title="Invite All" />
                  <std-button @click.native="$root.$emit('invite-survivors')" fa-icon="fas fa-user-plus" title="Invite Survivors" />
                  <std-button @click.native="initializeBattle" large :disabled="confirmedUsers.length === 0" fa-icon="fas fa-radiation" title="Start Battle" />
                </div>
              </div>

              <div v-if="invitedUsers.length > 0 || confirmedUsers.length > 0">
                <p class='my-0 highlight'>Confirmed players: {{ confirmedUsers.length }} of {{ invitedUsers.length + confirmedUsers.length}} invited</p>
                <small class='mt-0 font-italic'>Unconfirmed players will be uninvited when the battle begins.</small>
              </div>
              <div v-else>
                <p class="my-0">You haven't invited any players yet.</p>
                <small class='mt-0 font-italic'>Invite players from the leaderboard to join your battle.</small>
              </div>

            </div>

            <div v-else-if="battle.stage >= 3" class="flex-grow-1">
              <div class="controls d-flex justify-content-around flex-grow-1 h-100 w-100">
                <button class="large" @click="endBattle" :disabled="battle.stage < 4"><i class="fas fa-peace"></i>End Battle</button>
              </div>
            </div>
          </div>

          <!-- <div class="slidecontainer">
            <input type="range" min="0" max="100" v-model="volumeAmbianceInput" class="slider" id="ambiance-volume" @input="changeVolumeAmbiance">
          </div> -->

        </div>

        <div v-else class="flex-centering pt-0 pb-4">
          <div v-if="battle.stage >= 3 && currentUser.invite_status != 'survived'">
            <span class="d-flex justify-content-center">
              <a v-if="battle.stage === 4" :href="challengeUrl" target="_blank" class="mx-auto">
                <std-button large fa-icon="fas fa-rocket mr-1" title="Launch Codewars" />
              </a>
              <p v-else class="mx-auto">
                <std-button large fa-icon="fas fa-rocket mr-1" title="Launch Codewars" disabled />
              </p>
            </span>
            <div v-if="currentUser.invite_status == 'confirmed'">
              <!-- <p class="text-center">Click the button below once you have completed the kata on Codewars.</p> -->
              <span class="mx-auto">
                <div id="spinner" v-if="completedButtonClicked" class="centered display-initial">
                  <div class="lds-ring small"><div></div><div></div><div></div><div></div></div>
                </div>
                <std-button @click.native="completedChallenge" large fa-icon="fas fa-check-double mr-1" title="Challenge Completed" :disabled="completedButtonClicked || battle.stage < 4" />
              </span>
            </div>
          </div>
          <div v-else-if="currentUser.invite_status == 'invited'">
            <p class="text-center">You have been requested to join this battle.</p>
            <std-button large class="mx-auto" @click.native="$root.$emit('confirm-invite', currentUser.id)" title="Join battle" />
          </div>
          <div v-else-if="currentUser.invite_status == 'confirmed' && battle.stage > 0 && battle.stage < 3">
            <p class="text-center">You are confirmed for the next battle. Get ready!</p>
          </div>
          <div v-else-if="currentUser.invite_status == 'ineligible' || currentUser.invite_status == 'survived'">
            <p class="text-center">You completed this challenge<br/>{{ displayDateTime(currentUser.completed_at) }}.</p>
            <p v-if="battle.stage < 3" class="text-center">You can't participate in this battle.</p>
          </div>
          <div v-else>
            <p class="text-center">Requests to join battles will show up in this window.</p>
          </div>
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
      currentUser: Object,
      battle: Object,
      input: String,
      currentUserIsModerator: Boolean,
      countdown: Number,
      battleStatus: Object,
      challengeUrl: String,
      timeLimit: Number,
      volumeAmbiance: Number
    },
    data() {
      return {
        title: "SYS://Settings",
        challengeInput: this.input,
        completedButtonClicked: false,
        attentionHover: false,
        volumeAmbianceInput: this.volumeAmbiance * 100
      }
    },
    components: {
      StdButton: () => import('./shared/button.vue'),
    },
    computed: {
      seekAttention() {
        if ((!this.isConfirmed(this.currentUser) && this.isInvited(this.currentUser)) || (this.isConfirmed(this.currentUser) && this.battle.stage >= 3)) {
          return [`${ this.attentionHover ? 'paused ' : ''}animated infinite pulse seek-attention`]
        } else {
          return null
        }
      },
      eligibleUsers () {
        return this.users.filter(user => user.invite_status && user.invite_status !== 'ineligible')
      },
      ineligibleUsers () {
        const ineligibleUsers = this.users.filter(user => user.invite_status === 'ineligible')
        const message = `${ineligibleUsers.map(user => user.username ).join(", ")} already completed this kata and can't join the battle.`
        if (ineligibleUsers.length > 0) {
          this.$root.$emit('announce', {status: 'warning', content: message})
        }

        return ineligibleUsers
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
      allInvited() {
        return this.eligibleUsers.length === (this.invitedUsers.length + this.confirmedUsers.length);
      },
      allConfirmed() {
        return this.battle.stage === 2 && this.confirmedUsers.length === this.invitedUsers.length;
      },
      battleStage() {
        return this.battle.stage;
      },
      currentUserIsInvited() {
        return this.currentUser.invite_status === 'invited'
      },
      currentUserIsConfirmed() {
        return this.currentUser.invite_status === 'confirmed'
      },
    },
    watch: {
      battleStage: function() {
        this.completedButtonClicked = false;
      },
      currentUserIsInvited: function() {
        if (this.currentUserIsInvited) this.$root.$emit('play-fx', 'interface');
      },
      currentUserIsConfirmed: function() {
        // if (this.currentUserIsConfirmed) this.$root.$emit('play-fx', 'drums');
      },
    },
    methods: {
      completedChallenge() {
        this.completedButtonClicked = true;
        setTimeout(() => {
          this.completedButtonClicked = false;
        }, 3000)
        this.$root.$emit('fetch-challenges', this.currentUser.id);
      },
      isInvited(user) {
        return user.invite_status === 'invited'
      },
      isConfirmed(user) {
        return user.invite_status === 'confirmed'
      },
      createBattle() {
        this.$root.$emit('create-battle', this.challengeInput)
      },
      cancelBattle() {
        this.$root.$emit('delete-battle')
      },
      initializeBattle() {
        if (this.battle.stage < 3) { this.$root.$emit('initialize-battle') }
      },
      endBattle() {
        if (this.battle.stage > 3) { this.$root.$emit('end-battle') }
      },
      changeVolumeAmbiance() {
        this.$root.$emit('change-volume-ambiance', this.volumeAmbianceInput / 100)
      },
      displayDateTime(timestamp) {
        const monthNames = [
          "January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"
          ];
        const dateTime = new Date(timestamp)
        const yyyy = dateTime.getYear() + 1900;
        const M = monthNames[dateTime.getMonth()];
        const dd = dateTime.getDate();
        const hh = ("0" + dateTime.getHours()).slice(-2);
        const mm = ("0" + dateTime.getMinutes()).slice(-2);
        return `on ${dd} ${M} ${yyyy} at ${hh}:${mm}`;
      },
      editTimeLimit(step) {
        this.$root.$emit('edit-time-limit', step)
      }
    }
  }
</script>

<style scoped>
</style>
