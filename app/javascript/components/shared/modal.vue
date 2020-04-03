<template>
  <div>
    <div :class="['modal-overlay', { hidden: !show }]" @click="$root.$emit('close-modal')" />
    <widget :header-title="title" :seek-attention="true" :focus="show" class="modal-widget animated fadeIn faster" ref="widget">
      <slot />
    </widget>
  </div>
</template>

<script>
export default {
  props: {
    title: String,
    show: {
      type: Boolean,
      default: false,
    },
    width: {
      type: String,
      default: '600px',
    },
    maxHeight: {
      type: String,
      default: '80%',
    },
    show: Boolean,
  },
  mounted() {
    this.$el.style.position = 'absolute'
    this.$el.style.width = this.width
    this.$el.style.maxHeight = this.maxHeight;
    this.$el.style.left = `calc(50% - ${this.width} / 2)`
    this.$el.style.top = `calc(50% - ${this.$el.clientHeight}px / 2)`
  }
}
</script>

<style lang='scss' scoped>
  .modal-overlay {
    position: fixed;
    width: 100vw;
    height: 100vh;
    background-color: transparent;
    content: " ";
    top: 0;
    left: 0;
  }
</style>