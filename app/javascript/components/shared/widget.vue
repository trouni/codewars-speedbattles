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
  @import "../../stylesheets/variables.scss";
  
  .widget-message-box {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    clip-path: polygon(0 0, calc(100% - #{$bezel}) 0, 100% $bezel, 100% 100%, $bezel 100%, 0 calc(100% - #{$bezel}));
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    flex-grow: 1;
    backdrop-filter: blur(2px) contrast(90%);
    padding: 1em 2em;
    z-index: 10;
    &.w-100 {
      clip-path: unset;
      border-width: 1px 0;
      border-style: solid;
    }
  }
</style>