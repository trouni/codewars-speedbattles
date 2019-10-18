<template>
  <div id="menu-button">
    <div :class="['dropdown-toggle highlight-on-hover', { active: showMenu }]" @click="showMenu = !showMenu">
      <i class="fab fa-2x fa-old-republic"></i>
    </div>
    <div v-if="showMenu" :class="['menu widget-bg h-auto']">
      <div class="widget">
        <!-- <h3 class="header">SpeedBattles</h3> -->
        <div class="widget-body">
          <a v-if="roomId >= 0" href="/rooms/" @click="showMenu = false" class="button mx-3"><i class="fas fa-angle-double-left mr-1"></i>Leave room</a>
          <a @click="showMenu = false" href="/users/edit/" class="button mx-3"><i class="fas fa-cog mr-1"></i>Settings</a>
          <a href="/users/sign_out" data-method="delete" class="button mx-3" @click="showMenu = false"><i class="fas fa-sign-out-alt mr-1"></i>Log out</a>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    props: {
      roomId: Number,
    },
    data() {
      return {
        showMenu: false,
      }
    },
    // computed: {
    // },
    methods: {
    }
  }
</script>

<style scoped>
.widget {
  background: linear-gradient(154.9deg, rgba(0, 0, 0, 0.6) 0%, rgba(0, 0, 0, 0.9) 86.37%);
}
</style>
