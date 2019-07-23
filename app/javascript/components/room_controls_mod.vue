<template>
  <div id="room-controls" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <div class="edit-battle" v-if="this.battle">
      <h4>{{ battle.challenge.name }}</h4>
      <p>{{ ineligibleUsers }}</p>
      <button @click="$root.$emit('delete-battle')">Delete Battle</button>
      <button @click="$root.$emit('invite-all')">Invite All</button>
    </div>
    <div class="new-battle" v-else>
      <input type="text" v-model="challengeInput" placeholder="Enter the id, slug or url of a CodeWars Kata">
      <button @click="$root.$emit('create-battle', challengeInput)">Load</button>
    </div>
  </div>
</template>

<script>
  export default {
    props:{
      room: Object,
      battle: Object
    },
    data() {
      return {
        title: "Controls",
        challengeInput: ''
      }
    },
    computed: {
      ineligibleUsers () {
        return `${this.room.users.filter(user => user.invite_status == 'ineligible').map(user => user.username ).join(", ")} already completed this kata and are not eligible`
      }
    },
    methods: {
    }
  }
</script>

<style scoped>
</style>
