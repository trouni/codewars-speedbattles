<template>
  <div id="room-controls" class="widget">
    <h3 class="header highlight">{{ title }}</h3>
    <div class="widget-body">
      <div v-if="currentUserIsModerator">
        <div class="new-battle" v-if="!this.battle">
          <input class="input-field" type="text" v-model="challengeInput" @keyup.enter="createBattle" placeholder="Enter the id, slug or url of a CodeWars Kata">
          <button @click="createBattle" class="line-height-1">Load</button>
        </div>
        <div class="edit-battle" v-else-if="!this.battleInitialized">
          <!-- <input type="number" name="time-limit" min='1' placeholder="time limit"> min (optional)
          <input type="number" min='1' :max="eligibleUsers.length"> max survivors (optional) -->
          <p>{{ ineligibleUsers.map(user => user.username ).join(", ") }} already completed this kata and {{ ineligibleUsers.length > 1 ? 'are' : 'is' }} not eligible for the battle</p>
          <button @click="$root.$emit('delete-battle')">Delete Battle</button>
          <button @click="$root.$emit('invite-all')" :disabled="allInvited">Invite All</button>
        </div>
        <button v-if="battleLoaded" :disabled="!readyToStart" :class="{ 'all-confirmed': allConfirmed }" @click="initializeBattle">Start Battle ({{ confirmedUsers.length }} of {{ invitedUsers.length }})</button>
        <button v-else-if="battleInitialized" @click="endBattle">End Battle</button>
      </div>
      <div v-else>
        <div v-if="battleInitialized">
          Click the button below once you have completed the kata on CodeWars.
          <button @click="$root.$emit('fetch-challenges', currentUser.id)" :disabled="!battleStarted">Challenge Completed</button>
        </div>
        <div v-else-if="currentUser.invite_status == 'invited'">
          <button @click="$root.$emit('confirm-invite', currentUser.id)">Confirm Invite</button>
        </div>
        <div v-else-if="currentUser.invite_status == 'confirmed'">
          You are confirmed for the next battle. Get ready!
        </div>
        <div v-else>
          Invitations to join a battle will show up in this window.
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
      countdown: Number
    },
    data() {
      return {
        title: "SYS://Settings",
        challengeInput: this.input
      }
    },
    computed: {
      eligibleUsers () {
        return this.users.filter(user => user.invite_status && user.invite_status !== 'ineligible')
      },
      ineligibleUsers () {
        return this.users.filter(user => user.invite_status === 'ineligible')
      },
      invitedUsers() {
        if (!this.battle) { return [] }
        return this.battle.players
      },
      confirmedUsers() {
        if (!this.battle) { return [] }
        return this.battle.players.filter(user => user.invite_status == 'confirmed')
      },
      allInvited() {
        return this.invitedUsers.length === this.eligibleUsers.length
      },
      allConfirmed() {
        return this.readyToStart && this.confirmedUsers.length === this.invitedUsers.length
      },
      battleLoaded() {
        if (this.battle) {
          return this.battle.start_time === null
        }
      },
      readyToStart() {
        return this.battleLoaded && this.confirmedUsers.length > 0
      },
      battleInitialized() {
        if (this.battle) {
          return this.battle.start_time !== null && this.battle.end_time === null
        }
      },
      battleStarted() {
        if (this.battle) {
          return this.battle.start_time !== null && this.battle.end_time === null && this.countdown === 0
        }
      },
      battleOver() {
        if (this.battle) {
          return this.battle.start_time !== null && this.battle.end_time !== null
        }
      }
    },
    methods: {
      createBattle() {
        this.$root.$emit('create-battle', this.challengeInput)
      },
      initializeBattle() {
        if (!this.battleInitialized) { this.$root.$emit('initialize-battle') }
      },
      endBattle() {
        if (this.battleInitialized) { this.$root.$emit('end-battle') }
      }
    }
  }
</script>

<style scoped>
  .all-confirmed {
    background-color: green;
  }
</style>
