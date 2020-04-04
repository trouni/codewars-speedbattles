<template>
  <button
    @click="click"
    :disabled="disabled || loading"
    :class="[{ large: large, small: small }]"
    >
    <span @mouseenter="mouseEnter" class="hover-mask"></span>
    <spinner v-if="loading" />
    <i v-if="faIcon" :class="faIcon"></i>
    <slot>{{ title }}</slot>
  </button>
</template>

<script>
export default {
  props: {
    faIcon: {
        type: String,
        default: null
    },
    naked: Boolean,
    title: String,
    disabled: Boolean,
    large: Boolean,
    small: Boolean,
    loading: {
      type: Boolean,
      default: false,
    }
  },
  methods: {
    mouseEnter() {
      if (!this.disabled) this.$root.$emit('play-fx', 'mouseenter');
    },
    click() {
      if (!this.disabled) this.$root.$emit('play-fx', 'click');
    }
  }
};
</script>

<style scoped lang='scss'>
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