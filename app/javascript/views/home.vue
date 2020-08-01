<template>
  <div id="home" class="vh-100">
    <div class="absolute-center">
      <div class="max-w-100vw d-flex justify-content-center align-items-end mb-5">
        <logo />
      </div>

      <h4 class="tagline highlight mt-3 mb-5 large"><span class="highlight animated fadeIn delay-2s">Codewars.</span> <span class="animated highlight-red fadeIn delay-3s">Multiplayer.</span></h4>
      <!-- <h2 class="tagline highlight-red mb-5 large animated fadeIn delay-4s">Join the war.</h2> -->

      <widget
      id="home-login"
      class="animated fadeIn m-auto delay-4s p-0"
      header-title="AUTH://credentials/">
        <template>
          <div v-if="signedIn" class="d-contents">
            <div class="d-flex justify-content-around pb-4">
              <a href="/rooms">
                <std-button fa-icon="fas fa-radiation" large>Go to war rooms</std-button>
              </a>
            </div>
          </div>
          <div v-else class="d-flex flex-column justify-content-between align-items-center flex-grow-1 py-3">
            <h4 class="highlight-red mb-4">Join the battlefield...</h4>
            <login-form />
          </div>
        </template> 
        <template v-slot:secondary v-if="!signedIn">
          <div class="d-flex flex-column justify-content-between align-items-center flex-grow-1 py-3">
            <h4 class="highlight mb-4">No SpeedBattles account yet?</h4>
            <div class="d-flex flex-column justify-content-between align-items-center flex-grow-1">
              <a href="/rooms" class="d-flex justify-content-around">
                <std-button fa-icon="fas fa-eye" class="mb-3">View as a spectator</std-button>
              </a>
              <h5 class="m-0">OR</h5>
              <a href="/users/sign_up" class="">
                <std-button fa-icon="fas fa-star-of-life" large>Sign up</std-button>
              </a>
            </div>
          </div>
        </template>
      </widget>
    </div>
  </div>
</template>

<script>
import Logo from '../components/shared/logo.vue'
import LoginForm from '../components/sign_up/login_form.vue'

export default {
  components: {
    Logo,
    LoginForm
  },
  props: {
    settings: {
      type: Object,
      default: _ => {}
    },
    signedIn: {
      type: Boolean,
      default: false
    }
  },
}
</script>

<style lang="scss">
</style>