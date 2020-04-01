<template>
    <pre v-highlightjs="content" class="d-flex">
      <code :class="[lang, 'flex-grow-1']"></code>
    </pre>
</template>

<script>
export default {
  props: {
    lang: String,
    content: String,
  }
}
</script>

<style lang='scss'>
  .peace, .battle-loaded, .battle-confirmed {
    @import "highlight.js/scss/nord"
  }
  .brink-of-war, .ready-for-battle {
    @import 'highlight.js/scss/obsidian';
  }
  .war, .countdown {
    @import 'highlight.js/scss/ocean';
  }
</style>