<template>
  <div id="room-controls" :class="['widget-bg', seekAttention]" @mouseover="attentionHover = true" @mouseleave="attentionHover = false">
    <div class="widget">
      <h3 class="header highlight">{{ title }}</h3>
      <div class="widget-body">
        <div v-if="currentUserIsModerator" class="h-100 d-flex flex-column">

          <div class="new-battle">
            <input class="input-field w-100" type="text" v-model="challengeInput" @keyup.enter="createBattle" placeholder="ID, slug or url of CodeWars Kata" :disabled="battle.stage > 0">
            <button @click="createBattle" class="line-height-1 mt-4 mx-auto" v-if="battle.stage < 1">Load</button>
            <button @click="cancelBattle" class="line-height-1 mt-4 mx-auto" v-if="battle.stage > 0 && battle.stage < 3">Cancel</button>
          </div>

          <div class="flex-grow-1">

            <!-- <div class="battle-settings d-flex flex-grow-1 justify-content-between mt-5" v-if="battle.stage > 0 && battle.stage < 3">
              <p class="mx-3"><input type="number" name="time-limit" min='1' placeholder="Time limit" disabled> min</p>
              <p class="mx-3"><input type="number" name="max-survivors" min='1' :max="eligibleUsers.length" placeholder="Max survivors"></p>
            </div> -->

            <div v-if="battle.stage > 0 && battle.stage <= 2" class="controls d-flex flex-column h-100">
              <div class="d-flex justify-content-around flex-grow-1 h-100 w-100">
                <button @click="$root.$emit('invite-all')" :disabled="allInvited">Invite All</button>
                <button :disabled="confirmedUsers.length === 0" @click="initializeBattle">Start Battle</button>
              </div>
              <div v-if="invitedUsers.length > 0">
                <p :class="['my-0', { 'highlight': allConfirmed }]">Confirmed players: {{ confirmedUsers.length }} of {{ invitedUsers.length + confirmedUsers.length}} invited</p>
                <p class='mt-0 font-italic'>Unconfirmed players will be uninvited when the battle starts.</p>
              </div>
            </div>
            <div v-else-if="battle.stage >= 3" class="controls d-flex justify-content-around flex-grow-1 h-100 w-100">
              <button class="large" @click="endBattle" :disabled="battle.stage < 4">End Battle</button>
            </div>
          </div>

        </div>

        <div v-else class="flex-centering pt-0 pb-4">
          <div v-if="battle.stage >= 3">
            <span class="d-flex justify-content-center">
              <a :href="challengeUrl" target="_blank" class="button large mx-auto">Launch CodeWars</a>
            </span>
            <div v-if="currentUser.invite_status == 'confirmed'">
              <!-- <p class="text-center">Click the button below once you have completed the kata on CodeWars.</p> -->
              <button class="mx-auto large" @click="completedChallenge" :disabled="completedButtonClicked || battle.stage < 4">Challenge Completed</button>
            </div>
          </div>
          <div v-else-if="currentUser.invite_status == 'invited'">
            <p class="text-center">You have been requested to join this battle.</p>
            <button class="mx-auto large" @click="$root.$emit('confirm-invite', currentUser.id)">Join battle</button>
          </div>
          <div v-else-if="currentUser.invite_status == 'confirmed'">
            <p class="text-center">You are confirmed for the next battle. Get ready!</p>
          </div>
          <div v-else-if="currentUser.invite_status == 'ineligible'">
            <p class="text-center">You have already completed this challenge.<br/>You can't participate to this battle...</p>
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
      challengeUrl: String
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
    }
  }
</script>

<style scoped>
</style>
