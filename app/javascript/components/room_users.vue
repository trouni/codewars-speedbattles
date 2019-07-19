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
  export default {
    props: {
      users: Array,
      roomId: Number,
      userId: Number
    },
    data() {
      return {
        title: "CodeWarriors"
      }
    },
    channels: {
        UsersChannel: {
            connected() {
              this.$root.$emit('refresh-users')
            },
            rejected() {},
            received(data) {
              // console.log("ActionCable data => ", data)
              if (data.unsubscribed) {
                this.$root.$emit('remove-user', data)
                // this.removeFromUsers(data)
              } else {
                this.$root.$emit('push-user', data)
                // this.pushToUsers(data)
              }
              // this.$root.$emit('refreshUsers')
            },
            disconnected() {}
        }
    },
    mounted() {
        this.$cable.subscribe({ channel: 'UsersChannel', room_id: this.roomId, user_id: this.userId });
    },
    methods: {
      sendMessage() {
        const message = {
          chat_id: this.chatId,
          user_id: this.userId,
          content: this.input
        }
        this.$cable.perform({
            channel: 'ChatChannel',
            action: 'send_message',
            data: message
        });
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
