<template>
  <div>
    <div class="modal-overlay animated fadeIn faster" />
    <div class="modal-ctn" ref="ctn">
      <widget :header-title="title" :seek-attention="true" class="focus modal-widget animated fadeIn faster" ref="widget" :loading=loading>
        <template>
          <slot/>
        </template>
        <template v-slot:secondary v-if="$slots.secondary">
          <slot name="secondary" />
        </template>
        <template v-if="!controls.hide" v-slot:controls>
          <std-button v-if="controls.cancel" @click.native="cancel" fa-icon="fas fa-times-circle" >{{ controls.cancel }}</std-button>
          <std-button v-if="controls.submit" @click.native="submit" fa-icon="fas fa-save" large >{{ controls.submit }}</std-button>
        </template>
      </widget>
    </div>
  </div>
</template>

<script>
import EventBus from '../../services/event_bus'

export default {
  props: {
    title: String,
    loading: {
      type: Boolean,
      default: false,
    },
    show: {
      type: Boolean,
      default: false,
    },
    controls: {
      type: Object,
      default: () => {
        return {
          hide: false,
          cancel: "Cancel",
          submit: "Save"
        }
      },
    },
    maxWidth: {
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
    const maxWidth = this.$slots.secondary ? `calc(${this.maxWidth} * 2)` : this.maxWidth
    this.$refs.ctn.style.maxWidth = maxWidth
    this.$refs.ctn.style.maxHeight = this.maxHeight;
  
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
  .modal-ctn {
    position: absolute;
    display: flex;
    width: 100%;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 100;

    .widget-content {
      overflow-y: scroll;
    }
  }

  .modal-overlay {
    position: fixed;
    width: 100vw;
    height: 100vh;
    background-color: transparent;
    content: " ";
    top: 0;
    left: 0;
    z-index: 10;
  }
</style>