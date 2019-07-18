<template>
  <div id="room-users" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <ul class="list-group">
      <li v-bind:class="userClass(user)" v-for="user in users">
        <div>{{ user.username }} <i class="fas fa-crown" v-if="user.moderator"></i></div>
        <div v-if="user.invite_status == 'eligible'" @click="$root.$emit('invite-user', user.id)">invite</div>
        <div v-else-if="user.invite_status == 'invited'" @click="$root.$emit('uninvite-user', user.id)">uninvite</div>
        <div v-else></div>
      </li>
    </ul>
  </div>
</template>

<script>
  import SpeedBattlesApi from '../services/api/speedbattles_api'

  export default {
    props: {
      users: Array
    },
    data() {
      return {
        title: "CodeWarriors"
      }
    },
    methods: {
      userClass(user) {
        return [
          'list-group-item',
          'd-flex',
          'justify-content-between',
          user.invite_status
        ]
      }
    }
  }
</script>

<style scoped>
  .list-group-item {
    background: transparent;
    color: black;
  }

  .eligible {
    cursor: pointer;
  }

  .invited {
    color: orange;
  }

  .confirmed {
    color: green;
  }

  .ineligible {
    color: grey;
  }
</style>
