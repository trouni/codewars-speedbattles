<template>
  <div>
    <div :class="['modal-overlay', { hidden: !show }]" @click="cancel" />
    <widget :header-title="title" :seek-attention="true" :focus="show" class="modal-widget animated fadeIn faster" ref="widget">
      <template>
        <slot/>
      </template>
      <template v-slot:secondary v-if="$slots.secondary">
        <slot name="secondary" />
      </template>
      <template v-slot:controls>
        <std-button @click.native="cancel" fa-icon="fas fa-times-circle" >Cancel</std-button>
        <std-button @click.native="submit" fa-icon="fas fa-save" large >Save</std-button>
      </template>
    </widget>
  </div>
</template>

<script>
import EventBus from '../../services/event_bus'

export default {
  props: {
    title: String,
    show: {
      type: Boolean,
      default: false,
    },
    width: {
      type: String,
      default: '450px',
    },
    maxHeight: {
      type: String,
      default: '80%',
    },
    show: Boolean,
  },
  mounted() {
    const width = this.$slots.secondary ? `calc(${this.width} * 2)` : this.width
    this.$el.style.position = 'absolute'
    this.$el.style.display = 'flex'
    this.$el.style.width = width
    this.$el.style.maxHeight = this.maxHeight;
    this.$el.style.left = `calc(50% - ${width} / 2)`
    this.$el.style.top = `calc(50% - ${this.$el.clientHeight}px / 2)`
  },
  methods: {
    cancel() {
      EventBus.$emit('cancel')
    },
    submit() {
      EventBus.$emit('submit')
    },
  }
}
</script>

<style lang='scss'>
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