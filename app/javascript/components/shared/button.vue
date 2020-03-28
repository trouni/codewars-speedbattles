<template>
  <button
    @click="click"
    :disabled="disabled"
    :class="[{ large: large }]"
    >
    <span @mouseover="mouseOver" class="hover-mask"></span>
    <i v-if="faIcon" :class="faIcon"></i>
    {{ title }}
  </button>
</template>

<script>
export default {
  props: {
    faIcon: {
        type: String,
        default: null
    },
    title: String,
    disabled: Boolean,
    large: Boolean,
  },
  methods: {
    mouseOver() {
      if (!this.disabled) this.$root.$emit('play-fx', 'beep');
    },
    click() {
      if (!this.disabled) this.$root.$emit('play-fx', 'select');
    }
  }
};
</script>

<style scoped>
  button {
    position: relative;
  }

  .hover-mask {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
  }
</style>