<template>
  <div id="room-users">
    <h3 class="highlight">{{ title }}</h3>
    <ul class="list-group">
      <li class="list-group-item" v-bind:class="{ 'list-group-item-dark': user.invite_status == 'eligible', 'list-group-item-success': user.invite_status == 'confirmed', 'list-group-item-warning': user.invite_status == 'invited', 'list-group-item-secondary': user.invite_status == 'ineligible' }" v-for="user in roomUsers">
        {{ user.username }} <i class="fas fa-crown" v-if="user.moderator"></i>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  props: ["propRoomUsers"],
  data: function () {
    return {
      roomUsers: this.propRoomUsers,
      title: "CodeWarriors"
    }
  }
}
</script>

<style scoped>
</style>
