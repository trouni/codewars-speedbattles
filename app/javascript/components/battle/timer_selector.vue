<template>
  <div class="timer-selector">
    <div class="timer-input">
      <span v-if="editable" @mousedown="startEditTimeLimit(1)" @mouseout="stopEditTimeLimit()" @mouseup="stopEditTimeLimit()" class="timer-arrow arrow-up">&#9650;</span>
      <p v-if="timeLimit > 0" class="settings-timer">{{("0" + timeLimit).slice(-2)}}</p>
      <p v-else>No</p>
      <span v-if="editable" @mousedown="startEditTimeLimit(-1)" @mouseout="stopEditTimeLimit()" @mouseup="stopEditTimeLimit()" :class="['timer-arrow arrow-down', { disabled: timeLimit <= 0 }]">&#9660;</span>
    </div>
    <span class="ml-1">{{ timeLimit > 0 ? 'min' : 'limit' }}</span>
  </div>
</template>

<script>


export default {
  props: {
    timeLimit: Number,
    editable: Boolean,
  },
  data() {
    return {
      editInterval: null,
      editTimeout: null,
    }
  },
  methods: {
    startEditTimeLimit(step) {
      this.$root.$emit('edit-time-limit', step)
      this.editTimeout = setTimeout(_ => {
        this.editInterval = setInterval(_ => this.$root.$emit('edit-time-limit', step), 50)
      }, 300)
    },
    stopEditTimeLimit() {
      clearInterval(this.editInterval)
      clearTimeout(this.editTimeout)
      this.editInterval = null
      this.editTimeout = null
    },
  }
};
</script>

<style scoped lang="scss">
  .timer-selector {
    display: inline-flex;
  }

  .timer-input {
    position: relative;
    width: 1.5em;
    text-align: center;
    p {
      transition: font-size 0s !important;
    }
  }

  .timer-arrow {
    position: absolute;
    left: calc(50% - 0.5em);
    width: 1em;
    cursor: pointer;
    margin: 0;
    font-size: 0.9em;
    &.arrow-up {
      top: -1.1em;
    }
    &.arrow-down {
      bottom: -1em;
    }
    &.disabled {
      cursor: default;
      visibility: hidden;
    }
  }
</style>