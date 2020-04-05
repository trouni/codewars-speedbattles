import "controllers"
import "bootstrap";
import Vue from 'vue/dist/vue.esm'
import ActionCableVue from 'actioncable-vue';
import VueChatScroll from 'vue-chat-scroll'
import Room from '../components/room.vue'
import Widget from '../components/shared/widget.vue'
import NavBar from '../components/navbar.vue'
import SignUpFormInputs from '../components/sign_up/form_inputs.vue'
import StdButton from '../components/shared/button.vue'
import Modal from '../components/shared/modal.vue'
import Spinner from '../components/shared/spinner.vue'
import VueShowdown from 'vue-showdown'
import VueHighlightJS from 'vue-highlightjs'

Vue.component('room', Room)
Vue.component('widget', Widget)
Vue.component('navbar', NavBar)
Vue.component('std-button', StdButton)
Vue.component('modal', Modal)
Vue.component('spinner', Spinner)
Vue.component('sign-up-form-inputs', SignUpFormInputs)
Vue.prototype.speechSynthesis = window.speechSynthesis;

Vue.use(VueChatScroll)
Vue.use(VueHighlightJS)
Vue.use(VueShowdown, {
  // set default flavor of showdown
  flavor: 'vanilla',
  // set default options of showdown (will override the flavor options)
  options: {
    omitExtraWLInCodeBlocks: false,
    noHeaderId: true,
    ghCompatibleHeaderId: true,
    prefixHeaderId: null,
    headerLevelStart: 1,
    parseImgDimensions: false,
    simplifiedAutoLink: true,
    excludeTrailingPunctuationFromURLs: true,
    literalMidWordUnderscores: false,
    strikethrough: true,
    tables: false,
    ghCodeBlocks: true,
    ghMentions: true,
    ghMentionsLink: "https://www.codewars.com/users/{u}",
    emoji: true,
    openLinksInNewWindow: true,
    simpleLineBreaks: false,
    requireSpaceBeforeHeadingText: true,

  },
})

Vue.directive('focus', {
  inserted: function (el) {
      el.focus()
  }
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

