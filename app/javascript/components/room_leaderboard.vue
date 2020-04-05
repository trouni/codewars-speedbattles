<template>
  <widget id="room-leaderboard" :header-title="title" :loading="loading" :focus="focus">
    <div class="flex-grow-1 fixed-header">
      <table :class="['console-table d-table flex-grow-1', { 'no-stats': !room.show_stats }]">
        <thead>
          <tr>
            <th scope="col" :style="room.show_stats ? 'width: 50%;' : 'width: 100%;'"><span class="data">WARRIORS [{{ sortedLeaderboard.length }}]</span></th>
            <th v-if="room.show_stats" scope="col" style="width: 6%;"><span class="data">#</span></th>
            <th v-if="room.show_stats" scope="col" style="width: 12%;"><span class="data">SCORE</span></th>
            <th v-if="room.show_stats" scope="col" style="width: 12%;"><span class="data">BATTLES</span></th>
            <th v-if="room.show_stats" scope="col" style="width: 20%;"><span class="data">WON : LOST</span></th>
            <!-- <th v-if="room.show_stats" scope="col" style="width: 10%;"><span class="data">TOTAL</span></th> -->
          </tr>
        </thead>
        <tbody>
          <tr v-for="(user, index) in sortedLeaderboard" :class="{ 'highlight current-user': isCurrentUser(user.id) }" :title="user.username" :key="user.id">
            <th scope="row" class="justify-content-between">
              <span :class="['data username', {offline: !isOnline(user.id)}]">
                <span :class="['mr-1', { 'online highlight': isOnline(user.id), offline: !isOnline(user.id) }]">●</span>
                <!-- <span :class="userClass(user.id)" v-if="showInviteButton(user.id, 'eligible')" @click="$root.$emit('invite-user', user.id)">{{ user.username }}</span>
                <span :class="userClass(user.id)" v-else-if="showInviteButton(user.id, 'invited')" @click="$root.$emit('uninvite-user', user.id)">{{ user.username }}</span>
                <span :class="userClass(user.id)" @click="toggleInvite(user.id)" :disabled="!currentUserIsModerator">{{ user.name || user.username }} -->
                <span :class="userClass(user.id)">{{ user.name || user.username }}</span>
              </span>
              <span class="invite-button">
                <std-button v-if="showInviteButton(user.id)" @click.native="toggleInvite(user.id)" :title="showInviteButton(user.id)" small class="mr-2" />
              </span>
            </th>
            <td v-if="room.show_stats"><span class="data rank">{{ userRank(index) }}</span></td>
            <td v-if="room.show_stats"><span class="data">{{ leaderboard[user.id] ? displayScore(leaderboard[user.id].total_score) : "-" }}</span></td>
            <td v-if="room.show_stats"><span class="data">{{ leaderboard[user.id] ? leaderboard[user.id].battles_fought : "-" }}</span></td>
            <td v-if="room.show_stats"><span class="data">{{ leaderboard[user.id] ? `${leaderboard[user.id].battles_survived} : ${leaderboard[user.id].battles_lost}` : "-" }}</span></td>
            <!-- <td v-if="room.show_stats"><span class="data">{{ leaderboard[user.id] ? user.battles_fought : "-" }}</span></td> -->
          </tr>
        </tbody>
      </table>
    </div>
    <template v-slot:controls>
      <std-button
        v-if="room.show_stats"
        @click.native="showOfflineClicked"
        small
        :fa-icon="`far ${showOffline ? 'fa-eye-slash' : 'fa-eye'}`"
      >{{ showOffline ? 'Hide' : 'Show' }} offline users
      </std-button>
    </template>
  </widget>
</template>

<script>
export default {
  props: {
    roomPlayers: Array,
    users: Array,
    battle: Object,
    room: Object,
    currentUser: Object,
    currentUserIsModerator: Boolean,
    leaderboard: Object,
    loading: Boolean,
    initializing: Boolean,
    focus: Boolean,
  },
  components: {
    StdButton: () => import('./shared/button.vue'),
  },
  data() {
    return {
      showOffline: false,
    }
  },
  computed: {
    // moderator() {
    //   this.findUser(this.room.moderator.id);
    // },
    title() {
      return this.room.show_stats ? "NETWORK://Leaderboard" : "NETWORK://Users"
    },
    leaderboardUsers() {
      const allUsers = this.showOffline && this.roomPlayers ? this.roomPlayers.concat(this.users) : this.users;
      return allUsers.reduce((uniqueUsers, user) => {
        return uniqueUsers.map(user => user.username).includes(user.username) ? uniqueUsers : [...uniqueUsers, user]
      }, [])
    },
    sortedLeaderboard() {
      return this.leaderboardUsers.sort((a, b) => {
        if (this.leaderboard[a.id] && this.leaderboard[b.id]) {
          if (this.leaderboard[b.id].total_score !== this.leaderboard[a.id].total_score) {
            return this.leaderboard[b.id].total_score - this.leaderboard[a.id].total_score
          } else if (this.leaderboard[a.id].battles_fought === 0 || this.leaderboard[b.id].battles_fought === 0) {
            return this.leaderboard[b.id].battles_fought - this.leaderboard[a.id].battles_fought
          } else if (this.leaderboard[b.id].battles_survived !== this.leaderboard[a.id].battles_survived) {
              return this.leaderboard[b.id].battles_survived - this.leaderboard[a.id].battles_survived
          } else if (this.leaderboard[a.id].battles_lost !== this.leaderboard[b.id].battles_lost) {
              return this.leaderboard[a.id].battles_lost - this.leaderboard[b.id].battles_lost
          } else {
            return b.username[0] > a.username[0] ? 1 : -1
          }
        } else if (this.leaderboard[a.id] || this.leaderboard[b.id]) {
          return this.leaderboard[a.id] ? -1 : 1
        } else {
          return (new Date(a.joined_at) - new Date(b.joined_at))
        }
      })
    },
  },
  methods: {
    findUser(userId) {
      const index = this.users.findIndex((e) => e.id === userId);
      return this.users[index]
    },
    userRank(index) {
      if (index === 0) return 1

      if (this.displayScore(this.sortedLeaderboard[index].total_score) === this.displayScore(this.sortedLeaderboard[index - 1].total_score)) return '↑'

      return index + 1
    },
    displayScore(score) {
      if (score === 0) return 0

      return score > 0 ? `+${score}` : score
      // return Math.max(0, score);
    },
    defeats(player) {
      return player.battles_fought - player.battles_survived
    },
    showInviteButton(userId) {
      const user = this.findUser(userId)

      if (this.currentUserIsModerator && user && this.isOnline(userId) && this.battle && this.battle.stage > 0 && this.battle.stage < 3) {
        switch (user.invite_status) {
          case 'eligible':
            return 'invite'
            break

          case 'invited':
            return 'uninvite'
            break

          case 'confirmed':
            return 'uninvite'
            break

          default:
            return false
            break
        }

        // return this.currentUserIsModerator && this.findUser(userId).invite_status == inviteStatus
      }
    },
    isOnline(userId) {
      return this.users.map(e => e.id).includes(userId)
    },
    isCurrentUser(userId) {
      return this.currentUser.id === userId
    },
    userClass(userId) {
      const user = this.findUser(userId)

      if (user) {
        return [this.showInviteButton(userId) ? user.invite_status : '']
      } else {
        return []
      }
    },
    showOfflineClicked() {
      this.showOffline = !this.showOffline;
      if (this.showOffline) this.$root.$emit('show-offline-players');
    },
    toggleInvite(userId) {
      if (this.findUser(userId).invite_status == 'eligible' && this.currentUserIsModerator) this.$root.$emit('invite-user', userId)
      else this.$root.$emit('uninvite-user', userId)
    }
  }
}
</script>

<style scoped>
</style>
