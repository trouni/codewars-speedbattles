<template>
    <pre v-highlightjs="content" class="d-flex">
      <code :class="[lang, 'flex-grow-1']"></code>
    </pre>
</template>

<script>
import 'highlight.js/styles/sunburst.css'

export default {
  props: {
    lang: String,
    content: String,
  }
}
</script>

<style>

</style>