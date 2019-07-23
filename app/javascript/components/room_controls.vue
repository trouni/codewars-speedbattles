<template>
  <div id="room-controls" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <button @click="$root.$emit('confirm-invite', user.id)" v-if="user.invite_status == 'invited'">Confirm Invite</button>
  </div>
</template>

<script>
  export default {
    props: {
      room: Object,
      user: Object
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
