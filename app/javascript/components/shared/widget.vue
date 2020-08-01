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
  
  .widget-bg {
    padding: 0.5px 0.5px 1px 1px;
    clip-path: polygon(0 0, calc(100% - #{$bezel}) 0, 100% $bezel, 100% 100%, $bezel 100%, 0 calc(100% - #{$bezel}));
    height: 100%;
  }

  .initializing .widget-bg {
    opacity: 0;
  }

  .widget {
    position: relative;
    display: flex;
    overflow: hidden; // added this for the modal widget - was moving when scrolling over the controls
    background: linear-gradient(154.9deg, rgba(0, 0, 0, 0.55) 0%, rgba(0, 0, 0, 0.8) 86.37%);
    height: 100%;
    min-height: 100px;
    max-height: 90vh;
    box-shadow: 5px 5px 10px 0px rgba(0, 0, 0, 0.4);
    clip-path: polygon(0 0, calc(100% - #{$bezel}) 0, 100% $bezel, 100% 100%, $bezel 100%, 0 calc(100% - #{$bezel}));
    flex-direction: column;
    .header {
      clip-path: polygon(0 0, 100% 0, calc(100% - #{$bezel}) 100%, 0 100%);
      // width: fit-content;
      max-width: 100%;
      padding: 0 2.5em 0.1em 0.8em;
      line-height: 1.4em;
      opacity: 1;
      letter-spacing: 1px;
      text-transform: lowercase;
      font-size: 1em;
      margin: 0;
      z-index: 10;
      position: absolute;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .widget-content {
      overflow: hidden;
      height: 100%;
    }
    .widget-body {
      flex-grow: 1;
      flex-basis: 0;
      padding-left: $bezel;
      padding-right: $bezel;
      padding-top: 2em;
      display: flex;
      flex-direction: column;
      transition: filter 0.3s ease-out;
    }

    .widget-body:nth-child(2) {
      border-style: solid;
      border-width: 0.5px 0 0 0;
    }

    .widget-body.loading {
      filter: blur(3px);
    }
  }

  .widget-controls {
    min-height: 4em;
    display: flex;
    justify-content: space-around;
    align-items: center;
    padding: 0.5em 1.5em;
    background: linear-gradient(30deg, rgba(0,0,0,0.3), rgba(0,0,0,0.5));
    border-top-style: solid;
    border-top-width: 0.5px;

    input, textarea {
      position: relative;
      background-color: transparent;
      font-weight: 200;
      line-height: 1.7em;
    }
    
    input:focus, textarea:focus {
      box-shadow: none !important;
      background-color: transparent;
    }
  }

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

  @media screen and (min-width: $mobile-breakpoint) {
    .widget {
      .widget-content {
        display: flex;
        flex-grow: 1;
      }

      .widget-body:nth-child(2) {
        border-width: 0 0 0 0.5px;
      }
    }
  }
</style>