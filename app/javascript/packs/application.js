import "controllers"
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
Vue.prototype.speechSynthesis = window.speechSynthesis;

Vue.use(VueChatScroll)
Vue.use(VueShowdown, {
  // set default flavor of showdown
  flavor: 'github',
  // set default options of showdown (will override the flavor options)
  options: {
    emoji: true,
  },
})

Vue.directive('click-outside', {
  bind: function (el, binding, vnode) {
    el.clickOutsideEvent = function (event) {
      // here I check that click was outside the el and his childrens
      if (!(el == event.target || el.contains(event.target))) {
        // and if it did, call method provided in attribute value
        vnode.context[binding.expression](event);
      }
    };
    document.body.addEventListener('click', el.clickOutsideEvent)
  },
  unbind: function (el) {
    document.body.removeEventListener('click', el.clickOutsideEvent)
  },
});

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

