<template>
  <div id="room-leaderboard" class="widget-bg">
    <div class="widget">
      <h3 class="header">{{ title }}</h3>
      <div class="widget-body">
        <small class="ml-auto" v-if="room.show_stats">
          <a class="button" @click="showOfflineClicked">
            <i :class="['far', showOffline ? 'fa-eye-slash' : 'fa-eye']"></i>
            {{ showOffline ? 'Hide' : 'Show' }} offline players
          </a>
        </small>
        <table :class="['console-table', { 'no-stats': !room.show_stats }]">
          <thead>
            <tr>
              <th scope="col" :style="room.show_stats ? 'width: 50%;' : 'width: 100%;'"><span class="data">WARRIORS [{{ sortedLeaderboard.length }}]</span></th>
              <th v-if="room.show_stats" scope="col" style="width: 10%;"><span class="data">RANK</span></th>
              <th v-if="room.show_stats" scope="col" style="width: 10%;"><span class="data">SCORE</span></th>
              <th v-if="room.show_stats" scope="col" style="width: 10%;"><span class="data">WON</span></th>
              <th v-if="room.show_stats" scope="col" style="width: 14%;"><span class="data">COMPLETED/LOST</span></th>
              <th v-if="room.show_stats" scope="col" style="width: 10%;"><span class="data">TOTAL</span></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(player, index) in sortedLeaderboard" :class="{ 'highlight current-user': isCurrentUser(player.id) }" :title="player.username">
              <th scope="row">
                <span class="data username">
                  <span v-if="isOnline(player.id)" :class="['mr-1', { 'current-user highlight': isOnline(player.id), offline: !isOnline(player.id) }]">●</span>
                  <!-- <span :class="userClass(player.id)" v-if="showInviteButton(player.id, 'eligible')" @click="$root.$emit('invite-user', player.id)">{{ player.username }}</span>
                  <span :class="userClass(player.id)" v-else-if="showInviteButton(player.id, 'invited')" @click="$root.$emit('uninvite-user', player.id)">{{ player.username }}</span> -->
                  <span :class="userClass(player.id)" @click="toggleInvite(player.id)">{{ player.name || player.username }}
                    <!--  <i v-if="showInviteButton(player.id, 'confirmed')" class="fas fa-fist-raised highlight ml-1"></i> -->
                  </span>
                </span>
              </th>
              <td v-if="room.show_stats">
                <span class="data rank">{{ player.battles_fought ? index + 1 : "-" }}</span>
              </td>
              <td v-if="room.show_stats"><span class="data">{{ player.battles_fought ? player.total_score : "-" }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ player.battles_fought ? player.victories : "-" }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ player.battles_fought ? `${player.battles_survived} / ${defeats(player)}` : "-" }}</span></td>
              <td v-if="room.show_stats"><span class="data">{{ player.battles_fought ? player.battles_fought : "-" }}</span></td>
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
    currentUserIsModerator: Boolean
  },
  data() {
    return {
      title: "NETWORK://Leaderboard",
      showOffline: false,
    }
  },
  computed: {
    // moderator() {
    //   this.findUser(this.room.moderator.id);
    // },
    leaderboard() {
      const allUsers = this.showOffline ? this.roomPlayers.concat(this.users) : this.users;
      return allUsers.reduce((uniqueUsers, user) => {
        return uniqueUsers.map(user => user.username).includes(user.username) ? uniqueUsers : [...uniqueUsers, user]
      }, [])
    },
    sortedLeaderboard() {
      return this.leaderboard.sort((a, b) => {
        if (b.total_score !== a.total_score) {
          return b.total_score - a.total_score
        } else if (a.battles_fought === 0 || b.battles_fought === 0) {
          return b.battles_fought - a.battles_fought
        } else {
          if (b.victories !== a.victories) {
            return b.victories - a.victories
          } else {
            if (b.battles_survived !== a.battles_survived) {
              return b.battles_survived - a.battles_survived
            } else {
              if (this.defeats(a) !== this.defeats(b)) {
                return this.defeats(a) - this.defeats(b)
              } else {
                return b.username[0] > a.username[0] ? 1 : -1
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
          this.isOnline(userId) ? 'animated flipInY online' : 'offline'
        ]
      } else {
        return [
          this.isOnline(userId) ? 'animated flipInY online' : 'offline'
        ]
      }
    },
    showOfflineClicked() {
      this.showOffline = !this.showOffline;
      this.$root.$emit('get-room-players');
    },
    toggleInvite(userId) {
      if (this.findUser(userId).invite_status == 'eligible') this.$root.$emit('invite-user', userId)
      else this.$root.$emit('uninvite-user', userId)
    }
  }
}
</script>

<style scoped>
</style>
