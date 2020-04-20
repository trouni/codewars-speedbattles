<template>
  <span>
    <span v-for="(contentBlock, i) in contentBlocks" :key="i">
      <vue-showdown v-if="contentBlock.code === false" :markdown="contentBlock.content" :extensions="[processingRules]" />
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
  data() {
    return {
      processingRules: () => [
        // Removes <p> tags around text to allow html to display inline
        {
          type: 'output',
          filter: function(text, converter) {
            var re = /<\/?p[^>]*>/ig;
            text = text.replace(re, '');
            return text;
          }
        },
        {
          type: 'lang',
          regex: /\b([1-8]) ?(kyu|dan)s?\b/g,
          replace: '<span class="rank-hex smaller"><div class="small-hex $2-$1"><div class="inner-small-hex"><span>$1 $2</span></div></div></span>'
        },
      ],
    }
  },
  mounted() {
    this.$root.$emit('play-fx', 'message');
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
      const blocks = this.content.split(/^```\w*$/gm).map((block, idx) => {
        return {
          content: _.trim(block),
          code: idx % 2 === 1 ? this.blocksLang[(idx - 1) / 2] : false
        }
      })
      return blocks.filter(block => block.content)
    },
  },
  components: {
    CodeBlock: () => import('./code_block'),
  },
}
</script>

<style>

</style>