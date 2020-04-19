
<template>
  <div class="number-selector">
    <div class="number-input">
      <span v-if="editable" @mousedown="startEditNumber('+')" @mouseout="stopEditNumber()" @mouseup="stopEditNumber()" :class="['number-selector-arrow arrow-up', { disabled: value >= max }]">&#9650;</span>
      <div class="d-flex">
        <input v-if="editable" type="number" :value="value" ref="number" @input="updateValue" :class="{ appended: append }" />
        <p v-else type="number" v-html="value" ref="number" :class="{ appended: append }" />
        <span v-if="append" class="append" v-html="append" />
      </div>
      <span v-if="editable" @mousedown="startEditNumber('-')" @mouseout="stopEditNumber()" @mouseup="stopEditNumber()" :class="['number-selector-arrow arrow-down', { disabled: value <= min }]">&#9660;</span>
    </div>
  </div>
</template>

<script>


export default {
  props: {
    value: {
      type: Number,
      default: 0,
    },
    min: Number,
    max: Number,
    step: {
      type: Number,
      default: 1,
    },
    editable: Boolean,
    append: {
      type: String,
      default: null,
    },
  },
  data() {
    return {
      editInterval: null,
      editTimeout: null,
    }
  },
  watch: {
    value: function(newValue, oldValue) {
      this.resizeInput('' + newValue)
    }
  },
  mounted() {
    this.resizeInput('' + this.value)
  },
  methods: {
    increaseNumber() {
      const newValue = parseInt(this.$refs.number.value) + this.step
      this.$emit('input', this.restrictedValue(newValue))
    },
    decreaseNumber() {
      const newValue = parseInt(this.$refs.number.value) - this.step
      this.$emit('input', this.restrictedValue(newValue))
    },
    restrictedValue(value) {
      let newValue = Math.min(value, this.max || value)
      return Math.max(newValue, this.min || newValue)
    },
    updateValue(e) {
      const value = parseInt(e.currentTarget.value || 0)
      this.$refs.number.value = this.restrictedValue(value)
      this.$emit('input', this.restrictedValue(value))
    },
    resizeInput(value) {
      this.$refs.number.style.width = value.length * 10 + 'px'
    },
    startEditNumber(operation) {
      const action = operation === '+' ? this.increaseNumber : this.decreaseNumber
      action()
      this.editTimeout = setTimeout(_ => {
        this.editInterval = setInterval(action, 50)
      }, 300)
    },
    stopEditNumber() {
      clearInterval(this.editInterval)
      clearTimeout(this.editTimeout)
      this.editInterval = null
      this.editTimeout = null
    },
  }
};
</script>

<style lang="scss">
  .number-selector {
    position: relative;
    display: inline-flex;
    /* Chrome, Safari, Edge, Opera */
    input::-webkit-outer-spin-button,
    input::-webkit-inner-spin-button {
      -webkit-appearance: none;
      margin: 0;
    }

    input {
      text-align: center;
      background-color: transparent;
      border: none;
      /* Firefox */
      -moz-appearance: textfield;
    }
    input.appended {
      text-align: right;
    }
  }

  .number-input {
    position: relative;
    text-align: center;
    p {
      transition: font-size 0s !important;
    }
  }

  .number-selector-arrow {
    opacity: 0.5;
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
    width: 1em;
    cursor: pointer;
    margin: 0;
    font-size: 0.8em;
    &:hover {
      opacity: 1;
    }
    &.arrow-up {
      top: -1.2em;
    }
    &.arrow-down {
      bottom: -1.2em;
    }
    &.disabled {
      cursor: default;
      visibility: hidden;
    }
  }

  .append {
    margin-left: 0.5em;
  }
</style>