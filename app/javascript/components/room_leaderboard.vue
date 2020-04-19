<template>
  <widget id="room-leaderboard" :header-title="title" :loading="loading" :focus="focus">
    <div class="d-flex flex-column h-100">
      <div class="fixed-header">
        <table :class="['console-table h-100', { 'no-stats': !room.show_stats }]">
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
            <tr v-for="(user, index) in sortedLeaderboard" :class="{ 'highlight current-user': isCurrentUser(user.id) }" :title="`${user.username} (${-user.codewars.overall_rank} kyu)`" :key="user.id">
              <th scope="row" class="justify-content-between">
                <span :class="['data user', {offline: !user.online}]">
                  <span :class="['mr-1', { 'online highlight': user.online }]">●</span>
                  <!-- <span :class="userClass(user.id)" v-if="showInviteButton(user.id, 'eligible')" @click="$root.$emit('invite-user', user.id)">{{ user.username }}</span>
                  <span :class="userClass(user.id)" v-else-if="showInviteButton(user.id, 'invited')" @click="$root.$emit('uninvite-user', user.id)">{{ user.username }}</span>
                  <span :class="userClass(user.id)" @click="toggleInvite(user.id)" :disabled="!currentUserIsModerator">{{ user.name || user.username }} -->
                  <span :class="[userClass(user.id), 'username']">{{ user.name || user.username }}</span>
                </span>
                <span class="invite-button">
                  <std-button v-if="showInviteButton(user.id)" @click.native="toggleInvite(user.id)" :title="showInviteButton(user.id)" small class="mr-2" />
                </span>
              </th>
              <td v-if="room.show_stats"><span class="data rank">{{ userRanks[index] }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ user ? displayScore(user.total_score) : "-" }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ user ? user.battles_fought : "-" }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ user ? `${user.battles_survived || '-'} : ${user.battles_lost || '-'}` : "-" }}</span></td>
              <!-- <td v-if="room.show_stats"><span class="data">{{ user ? user.battles_fought : "-" }}</span></td> -->
            </tr>
          </tbody>
        </table>
      </div>
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
      return this.room.show_stats ? "NETWK://Leaderboard" : "NETWK://Users"
    },
    leaderboardUsers() {
      const allUsers = this.showOffline && this.roomPlayers ? this.roomPlayers.concat(this.users) : this.users;
      return allUsers.reduce((uniqueUsers, user) => {
        return uniqueUsers.map(user => user.username).includes(user.username) ? uniqueUsers : [...uniqueUsers, user]
      }, [])
    },
    sortedLeaderboard() {
      return this.leaderboardUsers.sort((a, b) => {
        if (b.total_score !== a.total_score) {
          return b.total_score - a.total_score
        } else if (b.battles_survived !== a.battles_survived) {
            return b.battles_survived - a.battles_survived
        } else if (a.battles_fought === 0 || b.battles_fought === 0) {
          return b.battles_fought - a.battles_fought
        } else if (a.battles_lost !== b.battles_lost) {
            return a.battles_lost - b.battles_lost
        } else if (a || b) {
          return a ? -1 : 1
        // } else {
        //   return b.username[0] > a.username[0] ? 1 : -1
        } else {
          return (new Date(a.joined_at) - new Date(b.joined_at))
        }
      })
    },
    userRanks() {
      let rank = 0
      let realRank = rank
      return this.sortedLeaderboard.map((user, index) => {
        realRank += 1
        if (index === 0 || user.total_score < this.sortedLeaderboard[index - 1].total_score) {
          rank = realRank
        }
        return rank
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

      if (this.displayScore(this.sortedLeaderboard[index].total_score) === this.displayScore(this.sortedLeaderboard[index - 1].total_score)) return '.' // '↑'

      return index + 1
    },
    displayScore(score) {
      return score > 0 ? `+${score}` : 0
      // return score > 0 ? `+${score}` : score
    },
    defeats(player) {
      return player.battles_fought - player.battles_survived
    },
    showInviteButton(userId) {
      const user = this.findUser(userId)

      if (this.currentUserIsModerator && user && user.online && this.battle && this.battle.stage > 0 && this.battle.stage < 3) {
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

<style lang='scss' scoped>
  .user {
    line-height: 1.5em;
    font-size: 1em;
    font-weight: 300;
    align-items: center;
    display: inline-flex;
    &.offline {
      opacity: 0.5;
    }
    &.offline .username {
      font-style: italic;
    }
    i.offline {
      font-style: normal;
    }
  }
</style>
