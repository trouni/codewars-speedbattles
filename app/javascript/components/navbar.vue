<template>
  <div id="menu-button" v-click-outside="hideMenu">
    <!-- <div :class="['corner-button highlight-on-hover', { active: showMenu }]" @click="showMenu = !showMenu"> -->
    <div class="corner-button highlight-on-hover" @click="$root.$emit('toggle-settings'); $root.$emit('play-fx', 'click');" @mouseenter="$root.$emit('play-fx', 'mouseenter')">
      <!-- <i class="fab fa-2x fa-old-republic"></i> -->
      <i class="fas fa-cog"></i>
    </div>
    <div v-if="showMenu" :class="['menu widget-bg h-auto p-0']">
      <div class="widget">
        <div class="widget-body py-3">
          
          <a href="/users/sign_out" data-method="delete" class="mx-3" @click="hideMenu">
            <std-button fa-icon="fas fa-sign-out-alt" title="Log out" />
          </a>
          <a v-if="roomId >= 0" href="/rooms/" @click="hideMenu" class="mx-3">
            <std-button fa-icon="fas fa-angle-double-left" title="Leave room" />
          </a>
          <std-button fa-icon="fas fa-cog" title="Settings" @click.native="$root.$emit('open-user-settings'); hideMenu();" class="mx-3" />
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
    components: {
      StdButton: () => import('./shared/button.vue'),
    },
    data() {
      return {
        showMenu: false,
      }
    },
    // computed: {
    // },
    methods: {
      hideMenu() {
        this.showMenu = false;
      },
    }
  }
</script>

<style scoped>
.widget {
  min-height: unset;
  background: linear-gradient(154.9deg, rgba(0, 0, 0, 0.7) 0%, rgba(0, 0, 0, 1) 86.37%);
}
</style>
