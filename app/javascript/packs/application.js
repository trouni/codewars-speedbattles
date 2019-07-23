import "bootstrap";
import Vue from 'vue/dist/vue.esm'
import ActionCableVue from 'actioncable-vue';
import VueChatScroll from 'vue-chat-scroll'
import Room from '../components/room.vue'

Vue.component('room', Room)

Vue.use(VueChatScroll)

Vue.use(ActionCableVue, {
    debug: true,
    debugLevel: 'error',
    connectionUrl: 'ws://localhost:3000/api/cable/'
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]'
  })
})


// import App from '../app.vue'
// import RoomUsers from '../components/room_users.vue'
// import RoomControls from '../components/room_controls.vue'
// import RoomControlsMod from '../components/room_controls_mod.vue'
// import RoomChat from '../components/room_chat.vue'
// import RoomLeaderboard from '../components/room_leaderboard.vue'
// import RoomBattle from '../components/room_battle.vue'
// Vue.component('app', App)
// Vue.component('room-users', RoomUsers)
// Vue.component('room-controls', RoomControls)
// Vue.component('room-controls-mod', RoomControlsMod)
// Vue.component('room-chat', RoomChat)
// Vue.component('room-leaderboard', RoomLeaderboard)
// Vue.component('room-battle', RoomBattle)
