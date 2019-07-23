<template>
  <div id="room-battle" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <h4 v-if="battle">{{ battle.challenge.name }}</h4>
    <p v-if="battle">{{ battle.challenge.description }}</p>
  </div>
</template>

<script>
  export default {
    props: {
      roomId: Number,
      battle: Object
    },
    data: function () {
      return {
        title: "Challenge"
      }
    },
    channels: {
      BattleChannel: {
          connected() {
            console.log('WebSockets connected to BattleChannel.')
          },
          rejected() {},
          received(data) {
            this.$root.$emit('update-battle', data)
          },
          disconnected() {}
      }
    },
    mounted() {
      this.$cable.subscribe({ channel: 'BattleChannel', room_id: this.roomId })
    },
  }
</script>

<style scoped>
</style>
