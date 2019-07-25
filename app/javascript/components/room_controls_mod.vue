<template>
  <div id="room-controls" :class="['widget-bg', seekAttention]">
    <div class="widget">
      <h3 class="header highlight">{{ title }}</h3>
      <div class="widget-body">
        <div v-if="currentUserIsModerator" class="h-100">

          <div class="new-battle d-flex">
            <input class="input-field flex-grow-1" type="text" v-model="challengeInput" @keyup.enter="createBattle" placeholder="ID, slug or url of CodeWars Kata" :disabled="battleStatus.battleLoaded">
            <button @click="createBattle" class="line-height-1" v-if="!battleStatus.battleLoaded">Load</button>
            <button @click="cancelBattle" class="line-height-1" v-if="battleStatus.battleLoaded && !battleStatus.battleInitialized">Cancel</button>
          </div>

          <div class="flex-centering flex-column pt-0 pb-4">

            <div class="battle-settings d-flex flex-grow-1 justify-content-between mt-5" v-if="battleStatus.battleLoaded && !battleStatus.battleInitialized">
              <p class="mx-3"><input type="number" name="time-limit" min='1' placeholder="Time limit" disabled> min</p>
              <p class="mx-3"><input type="number" name="max-survivors" min='1' placeholder="Max survivors" disabled></p> <!-- :max="eligibleUsers.length" -->
            </div>

            <div class="controls d-flex justify-content-around flex-grow-1 h-100 w-100">
              <button @click="$root.$emit('invite-all')" v-if="battleStatus.battleLoaded && !battleStatus.battleInitialized" :disabled="allInvited">Invite All</button>
              <button v-if="battleStatus.battleLoaded && !battleStatus.battleInitialized" :disabled="!battleStatus.readyToStart" @click="initializeBattle">Start Battle</button>
              <button class="large" v-else-if="battleStatus.battleInitialized" @click="endBattle" :disabled="!battleStatus.battleOngoing">End Battle</button>
            </div>

            <div v-if="!battleStatus.battleInitialized && invitedUsers.length > 0">
              <p :class="['my-0', { 'highlight': allConfirmed }]">Confirmed players: {{ confirmedUsers.length }} of {{ invitedUsers.length }}</p>
              <p class='mt-0 font-italic'>Unconfirmed players will be uninvited when the battle starts.</p>
            </div>

          </div>

        </div>

        <div v-else class="flex-centering pt-0 pb-4">
          <div v-if="battleStatus.battleInitialized">
            <p class="text-center">Click the button below once you have completed the kata on CodeWars.</p>
            <button class="mx-auto large" @click="$root.$emit('fetch-challenges', currentUser.id)" :disabled="!battleStatus.battleOngoing">Challenge Completed</button>
          </div>
          <div v-else-if="currentUser.invite_status == 'invited'">
            <p class="text-center">You have been requested to join this battle.</p>
            <button class="mx-auto large" @click="$root.$emit('confirm-invite', currentUser.id)">Join battle</button>
          </div>
          <div v-else-if="currentUser.invite_status == 'confirmed'">
            <p class="text-center">You are confirmed for the next battle. Get ready!</p>
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
      battleStatus: Object
    },
    data() {
      return {
        title: "SYS://Settings",
        challengeInput: this.input
      }
    },
    computed: {
      seekAttention() {
        if (this.isInvited(this.currentUser) && !this.isConfirmed(this.currentUser)) {
          return ['animated infinite pulse seek-attention']
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
        return this.battleStatus.readyToStart && this.confirmedUsers.length === this.invitedUsers.length
      },
    },
    methods: {
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
        if (!this.battleStatus.battleInitialized) { this.$root.$emit('initialize-battle') }
      },
      endBattle() {
        if (this.battleStatus.battleInitialized) { this.$root.$emit('end-battle') }
      },
    }
  }
</script>

<style scoped>
</style>
