<template>
  <div id="menu-button">
    <div v-if="loading" class="corner-button disabled">
      <i class="fas fa-cog" />
    </div>
    <div v-else class="corner-button highlight-on-hover clickable" @click="$root.$emit('toggle-settings'); $root.$emit('play-fx', 'click');" @mouseenter="$root.$emit('play-fx', 'mouseenter')">
      <i class="fas fa-cog" />
    </div>
  </div>
</template>

<script>
  export default {
    props: {
      loading: Boolean,
    },
  }
</script>

<style scoped>
</style>
