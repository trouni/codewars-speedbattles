<template>
  <div id="room-users" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <ul class="list-group">
      <li v-bind:class="userClass(user)" v-for="user in users">
        <div>{{ user.username }} <i class="fas fa-crown" v-if="user.moderator"></i></div>
        <div v-if="showInviteButton(user, 'eligible')" @click="$root.$emit('invite-user', user.id)">invite</div>
        <div v-else-if="showInviteButton(user, 'invited')" @click="$root.$emit('uninvite-user', user.id)">uninvite</div>
        <div v-else></div>
      </li>
    </ul>
  </div>
</template>

<script>
  export default {
    props: {
      users: Array,
      roomId: Number,
      currentUser: Object,
      currentUserIsModerator: Boolean
    },
    data() {
      return {
        title: "CodeWarriors"
      }
    },
    channels: {
    computed: {
    },
        UsersChannel: {
            connected() {
              console.log('WebSockets connected to UsersChannel')
              this.$root.$emit('refresh-users')
            },
            rejected() {},
            received(data) {
              if (data.unsubscribed) {
                this.$root.$emit('remove-user', data)
              } else {
                this.$root.$emit('push-user', data)
              }
              this.$root.$emit('refresh-all')
            },
            disconnected() {}
        }
    },
    mounted() {
        this.$cable.subscribe({ channel: 'UsersChannel', room_id: this.roomId, user_id: this.currentUser.id });
    },
    methods: {
      showInviteButton(user, inviteStatus) {
        return this.currentUserIsModerator && user.invite_status == inviteStatus
      },
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
