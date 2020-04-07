<template>
    <pre v-highlightjs="content" class="code-ctn">
      <spinner v-if="loading" />
      <code :class="[lang, 'flex-grow-1']" ref="codeContent" />
    </pre>
</template>

<script>
export default {
  props: {
    lang: String,
    content: String,
  },
  watch: {
    codeContent() {
      this.loading = !this.$refs.codeContent.innerText
    }
  },
  computed: {
    },
  methods: {
    codeContent() {
      return this.$refs.codeContent.innerText
    }
  },
}
</script>

<style lang='scss'>
  .code-ctn {
    display: flex;
    position: relative;
  }

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