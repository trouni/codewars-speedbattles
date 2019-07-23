<template>
  <div id="room-controls" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <button @click="$root.$emit('confirm-invite', currentUser.id)" v-if="currentUser.invite_status == 'invited'">Confirm Invite</button>
  </div>
</template>

<script>
  export default {
    props: {
      room: Object,
      currentUser: Object
    },
    data() {
      return {
        title: "Controls",
        challengeInput: ''
      }
    },
    computed: {
    },
    methods: {
    }
  }
</script>

<style scoped>
</style>
