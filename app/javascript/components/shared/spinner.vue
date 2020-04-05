<template>
    <div class="spinner absolute-center display-initial">
        <div class="lds-ring small"><div></div><div></div><div></div><div></div></div>
        <h3 class="animated fadeInDown faster"><slot /></h3>
    </div>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      default: null,
    }
  }
}
</script>

<style lang="scss" scoped>
.spinner {
  text-align: center;
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.spinner.absolute-center {
  position: absolute;
  top: calc(50% - 32px);
  right: calc(50% - 32px);
}

.lds-ring {
  display: inline-block;
  position: relative;
  width: 64px;
  height: 64px;
  &.small {
    transform: scale(.5, .5);
  }
}
.lds-ring div {
  box-sizing: border-box;
  display: block;
  position: absolute;
  width: 51px;
  height: 51px;
  margin: 6px;
  border: 8px solid white;
  border-radius: 50%;
  animation: lds-ring 1.2s cubic-bezier(0.5, 0, 0.5, 1) infinite;
  border-color: white transparent transparent transparent;
}
.lds-ring div:nth-child(1) {
  animation-delay: -0.45s;
}
.lds-ring div:nth-child(2) {
  animation-delay: -0.3s;
}
.lds-ring div:nth-child(3) {
  animation-delay: -0.15s;
}
@keyframes lds-ring {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

</style>