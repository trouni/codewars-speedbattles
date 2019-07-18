<template>
  <div id="room-battle" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <h4 v-if="activeBattle">{{ activeBattle.challenge.name }}</h4>
    <p v-if="activeBattle">{{ activeBattle.challenge.description }}</p>
  </div>
</template>

<script>
export default {
  props: {
    activeBattle: Object
  },
  data: function () {
    return {
      title: "Challenge"
    }
  }
}
</script>

<style scoped>
</style>
