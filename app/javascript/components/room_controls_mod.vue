<template>
  <div id="room-controls" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <div class="new-battle" v-if="!this.battle">
      <input type="text" v-model="challengeInput" placeholder="Enter the id, slug or url of a CodeWars Kata">
      <button @click="createBattle">Load</button>
    </div>
    <div class="edit-battle" v-else-if="!this.ongoingBattle">
      <input type="number" name="time-limit" min='1' placeholder="time limit"> min (optional)
      <input type="number" min='1' :max="eligibleUsers.length"> max survivors (optional)
      <p>{{ ineligibleUsers.map(user => user.username ).join(", ") }} already completed this kata and {{ ineligibleUsers.length > 1 ? 'are' : 'is' }} not eligible for the battle</p>
      <button @click="$root.$emit('delete-battle')">Delete Battle</button>
      <button @click="$root.$emit('invite-all')" :disabled="allInvited">Invite All</button>
    </div>
    <button v-if="battleLoaded" :disabled="!readyToStart" :class="{ 'all-confirmed': allConfirmed }" @click="startBattle">Start Battle ({{ confirmedUsers.length }} of {{ invitedUsers.length }})</button>
    <button v-else-if="ongoingBattle" @click="endBattle">End Battle</button>
  </div>
</template>

<script>
  export default {
    props: {
      room: Object,
      users: Array,
      currentUser: Object,
      battle: Object,
      input: String
    },
    data() {
      return {
        title: "Controls",
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
      ongoingBattle() {
        if (this.battle) {
          return this.battle.start_time !== null && this.battle.end_time === null
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
      startBattle() {
        if (!this.ongoingBattle) { this.$root.$emit('start-battle') }
      },
      endBattle() {
        if (this.ongoingBattle) { this.$root.$emit('end-battle') }
      }
    }
  }
</script>

<style scoped>
  .all-confirmed {
    background-color: green;
  }
</style>
