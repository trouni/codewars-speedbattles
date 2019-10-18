import "bootstrap";
import Vue from 'vue/dist/vue.esm'
import ActionCableVue from 'actioncable-vue';
import VueChatScroll from 'vue-chat-scroll'
import Room from '../components/room.vue'
import NavBar from '../components/navbar.vue'
import SignUpFormInputs from '../components/sign_up/form_inputs.vue'
import VueShowdown from 'vue-showdown'


Vue.component('room', Room)
Vue.component('navbar', NavBar)
Vue.component('sign-up-form-inputs', SignUpFormInputs)

Vue.use(VueChatScroll)
Vue.use(VueShowdown, {
  // set default flavor of showdown
  flavor: 'github',
  // set default options of showdown (will override the flavor options)
  options: {
    emoji: true,
  },
})

Vue.use(ActionCableVue, {
    debug: process.env.NODE_ENV === "development",
    debugLevel: 'error',
    connectionUrl: `${process.env.NODE_ENV === "production" ? "wss://speedbattles.herokuapp.com" : "ws://localhost:3000"}/cable`
    // connectionUrl: 'wss://localhost:3000/cable/'
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]'
  })
})
