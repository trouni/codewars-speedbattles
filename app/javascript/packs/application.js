import "bootstrap";
import Vue from 'vue/dist/vue.esm'
import App from '../app.vue'
import Room from '../components/room.vue'
import RoomUsers from '../components/room_users.vue'
import RoomControls from '../components/room_controls.vue'
import RoomChat from '../components/room_chat.vue'
import RoomLeaderboard from '../components/room_leaderboard.vue'
import RoomChallenge from '../components/room_challenge.vue'

Vue.component('app', App)
Vue.component('room', Room)
Vue.component('room-users', RoomUsers)
Vue.component('room-controls', RoomControls)
Vue.component('room-chat', RoomChat)
Vue.component('room-leaderboard', RoomLeaderboard)
Vue.component('room-challenge', RoomChallenge)

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]'
  })
})
