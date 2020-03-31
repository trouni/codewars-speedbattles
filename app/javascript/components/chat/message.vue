<template>
  <span>
    <span v-for="(contentBlock, i) in contentBlocks" :key="i">
      <vue-showdown v-if="contentBlock.code === false" :markdown="contentBlock.content" />
      <code-block v-else :content="contentBlock.content" :lang="contentBlock.code" />
    </span>
  </span>
</template>

<script>
import trim from 'lodash'

export default {
  name: 'chat-message',
  props: {
    content: String,
  },
  computed: {
    blocksLang() {
      const fenceRegex = /^```(?<lang>\w*)$/gm;
      var results, output = [];
      let i = 0;
      while (results = fenceRegex.exec(this.content)) {
        if(i % 2 == 0) output.push(results.groups.lang)
        i += 1;
      }
      return output
    },
    contentBlocks() {
      return this.content.split(/^```\w*$/gm).map((block, idx) => {
        return {
          content: _.trim(block),
          code: idx % 2 === 1 ? this.blocksLang[(idx - 1) / 2] : false
        }
      })
    }
  },
  components: {
    CodeBlock: () => import('./code_block'),
  },
}
</script>

<style>

</style>