<template>
  <div id="room-controls" :class="['widget-bg', seekAttention]" @mouseover="attentionHover = true" @mouseleave="attentionHover = false">
    <div class="widget">
      <h3 class="header highlight">{{ title }}</h3>
      <div class="widget-body">
        <div v-if="currentUserIsModerator" class="h-100 d-flex flex-column">

          <div class="new-battle d-flex flex-column h-100">
            <input class="input-field w-100" type="text" v-model="challengeInput" @keyup.enter="createBattle" placeholder="ID, slug or url of CodeWars Kata" :disabled="battle.stage > 0">
            <button @click="createBattle" class="line-height-1 mt-4 mx-auto large" v-if="battle.stage < 1"><i class="fas fa-cloud-upload-alt"></i>Load</button>

            <div class="battle-settings d-flex flex-column flex-grow-1 pb-3" v-if="battle.stage > 0 && battle.stage < 3">

              <div class="d-flex justify-content-between mt-1 line-height-1 flex-grow-1 align-items-stretch flex-grow-1">
                <div class='d-flex justify-content-center align-items-center'>
                  <h6 class="m-0"><strong>Time Limit:</strong><br/></h6>
                  <div class="timer-input text-center ml-3">
                    <h4 @click="editTimeLimit(5)" class="timer-arrow">&#9650;</h4>
                    <p v-if="timeLimit > 0" class="m-1 settings-timer">{{("0" + timeLimit).slice(-2)}}</p>
                    <p v-else class="m-1">none</p>
                    <h4 @click="editTimeLimit(-5)" :class="['timer-arrow', { disabled: timeLimit <= 0 }]">&#9660;</h4>
                  </div>
                  <span v-if="timeLimit > 0">min</span>
                </div>
                <div class="d-flex flex-column justify-content-around align-items-end">
                  <button @click="cancelBattle"><i class="far fa-times-circle"></i>Cancel</button>
                  <button @click="$root.$emit('invite-all')" :disabled="allInvited"><i class="fas fa-user-plus"></i>Invite All</button>
                  <button :disabled="confirmedUsers.length === 0" @click="initializeBattle" class="large"><i class="fas fa-radiation"></i>Start Battle</button>
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



        </div>

        <div v-else class="flex-centering pt-0 pb-4">
          <div v-if="battle.stage >= 3 && currentUser.invite_status != 'survived'">
            <span class="d-flex justify-content-center">
              <a v-if="battle.stage === 4" :href="challengeUrl" target="_blank" class="button large mx-auto"><i class="fas fa-rocket mr-1"></i>Launch CodeWars</a>
              <p v-else class="button large mx-auto disabled"><i class="fas fa-rocket mr-1"></i>Launch CodeWars</p>
            </span>
            <div v-if="currentUser.invite_status == 'confirmed'">
              <!-- <p class="text-center">Click the button below once you have completed the kata on CodeWars.</p> -->
              <button class="mx-auto large" @click="completedChallenge" :disabled="completedButtonClicked || battle.stage < 4"><i class="fas fa-check-double mr-1"></i>Challenge Completed</button>
            </div>
          </div>
          <div v-else-if="currentUser.invite_status == 'invited'">
            <p class="text-center">You have been requested to join this battle.</p>
            <button class="mx-auto large" @click="$root.$emit('confirm-invite', currentUser.id)">Join battle</button>
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
    },
    data() {
      return {
        title: "SYS://Settings",
        challengeInput: this.input,
        completedButtonClicked: false,
        attentionHover: false
      }
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
    },
    watch: {
      battleStage: function() {
        this.completedButtonClicked = false;
      }
    },
    methods: {
      completedChallenge() {
        this.completedButtonClicked = true;
        setTimeout(() => {
          this.completedButtonClicked = false;
        }, 5000)
        $root.$emit('fetch-challenges', currentUser.id);
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
