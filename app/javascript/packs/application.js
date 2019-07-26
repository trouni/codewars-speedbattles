import "bootstrap";
import Vue from 'vue/dist/vue.esm'
import ActionCableVue from 'actioncable-vue';
import VueChatScroll from 'vue-chat-scroll'
import Room from '../components/room.vue'
import SignUpFormInputs from '../components/sign_up/form_inputs.vue'

Vue.component('room', Room)
Vue.component('sign-up-form-inputs', SignUpFormInputs)

Vue.use(VueChatScroll)

Vue.use(ActionCableVue, {
    debug: true,
    debugLevel: 'error',
    connectionUrl: `${process.env.NODE_ENV === "production" ? "wss://speedbattles.herokuapp.com" : "ws://localhost:3000"}/cable`
    // connectionUrl: 'wss://localhost:3000/cable/'
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]'
  })
})
