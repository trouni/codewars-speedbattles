<template>
  <div :class="['widget-ctn', { 'seek-attention': seekAttention, focus: focus }]">
    <div class="widget-bg">
      <div class="widget">
        <h3 class="header" v-html="headerTitle" />
        <spinner v-if="loading" />
        <div class="widget-content">
          <div class="widget-body">
            <slot />
          </div>
          <div v-if="$slots.secondary" class="widget-body">
            <slot name="secondary" />
          </div>
        </div>
        <div v-if="$slots.controls" class="widget-controls">
          <slot name="controls"/>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: String,
    loading: {
      type: Boolean,
      default: false,
    },
    seekAttention: {
      type: Boolean,
      default: false,
    },
    focus: {
      type: Boolean,
      default: false,
    }
  },
}
</script>

<style lang='scss'>
</style>