<template>
  <div id="room-leaderboard" class="widget-bg">
    <div class="widget">
      <h3 class="header">{{ title }}</h3>
      <div class="widget-body">
        <small class="ml-auto" v-if="room.show_stats">
          <std-button @click.native="showOfflineClicked" :fa-icon="`far ${showOffline ? 'fa-eye-slash' : 'fa-eye'}`" :title="`${showOffline ? 'Hide' : 'Show' } offline players`" />
        </small>
        <table :class="['console-table', { 'no-stats': !room.show_stats }]">
          <thead>
            <tr>
              <th scope="col" :style="room.show_stats ? 'width: 40%;' : 'width: 100%;'"><span class="data">WARRIORS [{{ sortedLeaderboard.length }}]</span></th>
              <!-- <th v-if="room.show_stats" scope="col" style="width: 10%;"><span class="data">RANK</span></th> -->
              <th v-if="room.show_stats" scope="col" style="width: 15%;"><span class="data">SCORE</span></th>
              <th v-if="room.show_stats" scope="col" style="width: 15%;"><span class="data">BATTLES</span></th>
              <th v-if="room.show_stats" scope="col" style="width: 30%;"><span class="data">WON : LOST</span></th>
              <!-- <th v-if="room.show_stats" scope="col" style="width: 10%;"><span class="data">TOTAL</span></th> -->
            </tr>
          </thead>
          <tbody>
            <tr v-for="(player, index) in sortedLeaderboard" :class="{ 'highlight current-user': isCurrentUser(player.id) }" :title="player.username" :key="player.id">
              <th scope="row">
                <span class="data username">
                  <span v-if="isOnline(player.id)" :class="['mr-1', { 'current-user highlight': isOnline(player.id), offline: !isOnline(player.id) }]">●</span>
                  <!-- <span :class="userClass(player.id)" v-if="showInviteButton(player.id, 'eligible')" @click="$root.$emit('invite-user', player.id)">{{ player.username }}</span>
                  <span :class="userClass(player.id)" v-else-if="showInviteButton(player.id, 'invited')" @click="$root.$emit('uninvite-user', player.id)">{{ player.username }}</span> -->
                  <span :class="userClass(player.id)" @click="toggleInvite(player.id)" :disabled="!currentUserIsModerator">{{ player.name || player.username }}
                    <!--  <i v-if="showInviteButton(player.id, 'confirmed')" class="fas fa-fist-raised highlight ml-1"></i> -->
                  </span>
                </span>
              </th>
              <!-- <td v-if="room.show_stats"><span class="data rank">{{ leaderboard[player.id] ? index + 1 : "-" }}</span></td> -->
              <td v-if="room.show_stats"><span class="data">{{ leaderboard[player.id] ? displayScore(leaderboard[player.id].total_score) : "-" }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ leaderboard[player.id] ? leaderboard[player.id].battles_fought : "-" }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ leaderboard[player.id] ? `${leaderboard[player.id].battles_survived} : ${leaderboard[player.id].battles_lost}` : "-" }}</span></td>
              <!-- <td v-if="room.show_stats"><span class="data">{{ leaderboard[player.id] ? player.battles_fought : "-" }}</span></td> -->
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
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
    leaderboard: Object
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
    }
  },
  methods: {
    findUser(userId) {
      const index = this.users.findIndex((e) => e.id === userId);
      return this.users[index]
    },
    displayScore(score) {
      return Math.max(0, score);
    },
    defeats(player) {
      return player.battles_fought - player.battles_survived
    },
    showInviteButton(userId) {
      if (this.isOnline(userId) && this.battle && this.battle.stage > 0 && this.battle.stage < 3) {
        return this.currentUserIsModerator
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
        const inviteStatus = user.invite_status
        return [
          this.showInviteButton(userId) ? inviteStatus : '',
          // this.isOnline(userId) ? 'animated flipInY online' : 'offline'
        ]
      } else {
        return [
          // this.isOnline(userId) ? 'animated flipInY online' : 'offline'
        ]
      }
    },
    showOfflineClicked() {
      this.showOffline = !this.showOffline;
      this.$root.$emit('get-room-players');
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
