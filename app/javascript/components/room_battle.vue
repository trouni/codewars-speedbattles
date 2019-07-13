<template>
  <div id="room-challenge">
    <h3 class="highlight">{{ title }}</h3>
    <h4 v-if="activeBattle">{{ activeBattle.challenge.name }}</h4>
  </div>
</template>

<script>
export default {
  props: ["propBattle"],
  data: function () {
    return {
      title: "Challenge",
      activeBattle: this.propBattle
    }
  }
}
</script>

<style scoped>
</style>
