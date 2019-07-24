<template>
  <div id="room-leaderboard" class="widget">
    <h3 class="header highlight">{{ title }}</h3>
    <div class="widget-body">
      <table class="console-table">
        <thead>
          <th scope="col"><span class="data">WARRIORS [{{ sortedLeaderboard.length }}]</span></th>
          <th scope="col"><span class="data">RANK</span></th>
          <th scope="col"><span class="data">SCORE</span></th>
          <th scope="col"><span class="data">WON</span></th>
          <th scope="col"><span class="data">COMPLETED/LOST</span></th>
          <th scope="col"><span class="data">TOTAL</span></th>
        </thead>
        <tbody>
          <tr v-for="(player, index) in sortedLeaderboard">
            <th scope="row">
              <span class="data username">
                <i :class="['mr-1', { highlight: isOnline(player.id) }, { offline: !isOnline(player.id) }]">●</i>
                <span v-bind:class="userClass(player.id)" v-if="showInviteButton(player.id, 'eligible')" @click="$root.$emit('invite-user', player.id)">{{ player.username }}</span>
                <span v-bind:class="userClass(player.id)" v-else-if="showInviteButton(player.id, 'invited')" @click="$root.$emit('uninvite-user', player.id)">{{ player.username }}</span>
                <span v-bind:class="userClass(player.id)" v-else>{{ player.username }}
                  <!--  <i v-if="showInviteButton(player.id, 'confirmed')" class="fas fa-fist-raised highlight ml-1"></i> -->
                </span>
              </span>
            </th>
            <td>
              <span class="data rank">{{ index + 1 }}</span>
            </td>
            <td><span class="data">{{ player.total_score }}</span></td>
            <td><span class="data">{{ player.victories }}</span></td>
            <td><span class="data">{{ player.battles_survived }} / {{ defeats(player) }}</span></td>
            <td><span class="data">{{ player.battles_fought }}</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    leaderboard: Array,
    users: Array,
    room: Object,
    currentUser: Object,
    currentUserIsModerator: Boolean
  },
  data() {
    return {
      title: "NETWORK://Leaderboard"
    }
  },
  computed: {
    moderator() {
      this.findUser(this.room.moderator.id);
    },
    sortedLeaderboard() {
      return this.leaderboard.sort((a, b) => {
        if (b.total_score - a.total_score !== 0) {
          return b.total_score - a.total_score
        } else if (a.battles_fought === 0 || b.battles_fought === 0) {
          return b.battles_fought - a.battles_fought
        } else {
          if (b.victories - a.victories !== 0) {
            return b.victories - a.victories
          } else {
            if (b.battles_survived - a.battles_survived !== 0) {
              return b.battles_survived - a.battles_survived
            } else {
              if (this.defeats(a) - this.defeats(b) !== 0) {
                return this.defeats(a) - this.defeats(b)
              }
            }
          }
        }
      })
    }
  },
  methods: {
    findUser(userId) {
      const index = this.users.findIndex((e) => e.id === userId);
      return this.users[index]
    },
    defeats(player) {
      return player.battles_fought - player.battles_survived
    },
    showInviteButton(userId, inviteStatus) {
      if (this.isOnline(userId)) {
        return this.currentUserIsModerator && this.findUser(userId).invite_status == inviteStatus
      }
    },
    isOnline(userId) {
      return this.users.map(e => e.id).includes(userId)
    },
    userClass(userId) {
      const user = this.findUser(userId)

      if (user) {
        return [
          user.invite_status,
          { online: this.isOnline(userId) },
          { offline: !this.isOnline(userId) }
        ]
      } else {
        return [
          { online: this.isOnline(userId) },
          { offline: !this.isOnline(userId) }
        ]
      }
    }
  }
}
</script>

<style scoped>
  #room-leaderboard {
    overflow: scroll;
  }
</style>
