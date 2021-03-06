import "controllers"
import "bootstrap";
import Vue from 'vue/dist/vue.esm'
import ActionCableVue from 'actioncable-vue';
import VueChatScroll from 'vue-chat-scroll'
import App from '../app.vue'
import Room from '../views/room.vue'
import Home from '../views/home.vue'
import RoomsIndex from '../views/rooms_index.vue'
import Widget from '../components/shared/widget.vue'
import NavBar from '../components/shared/navbar.vue'
import SignUpFormInputs from '../components/sign_up/form_inputs.vue'
import StdButton from '../components/shared/button.vue'
import NumberInput from '../components/shared/num_input.vue'
import Modal from '../components/shared/modal.vue'
import Spinner from '../components/shared/spinner.vue'
import RankHex from '../components/shared/rank_hex.vue'
import VueShowdown from 'vue-showdown'
import VueHighlightJS from 'vue-highlightjs'

Vue.component('app', App)
Vue.component('home', Home)
Vue.component('rooms-index', RoomsIndex)
Vue.component('room', Room)
Vue.component('widget', Widget)
Vue.component('navbar', NavBar)
Vue.component('std-button', StdButton)
Vue.component('num-input', NumberInput)
Vue.component('modal', Modal)
Vue.component('spinner', Spinner)
Vue.component('rank-hex', RankHex)
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
    ghMentionsLink: "https://www.codewars.com/users/{u}/completed",
    emoji: true,
    openLinksInNewWindow: true,
    simpleLineBreaks: true,
    requireSpaceBeforeHeadingText: true,
    backslashEscapesHTMLTags: true,
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
  connectionUrl: process.env.WS_URL
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]'
  })
})

