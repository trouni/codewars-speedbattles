<template>
  <div id="room-controls" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <button @click="$root.$emit('confirm-invite', userId)">Confirm Invite</button>
  </div>
</template>

<script>
  export default {
    props: {
      room: Object,
      userId: Number
    },
    data() {
      return {
        title: "Controls",
        challengeInput: ''
      }
    },
    methods: {
    }
  }
</script>

<style scoped>
</style>
