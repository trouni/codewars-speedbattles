<template>
  <div id="menu-button" v-click-outside="hideMenu">
    <!-- <div :class="['corner-button highlight-on-hover', { active: showMenu }]" @click="showMenu = !showMenu"> -->
    <div class="corner-button highlight-on-hover" @click="$root.$emit('toggle-settings'); $root.$emit('play-fx', 'click');" @mouseenter="$root.$emit('play-fx', 'mouseenter')">
      <!-- <i class="fab fa-2x fa-old-republic"></i> -->
      <i class="fas fa-cog"></i>
    </div>
    <div v-if="showMenu" :class="['menu widget-bg h-auto p-0']">
      <div class="widget">
        <!-- <h3 class="header">SpeedBattles</h3> -->
        <div class="widget-body py-3">
          
          <a href="/users/sign_out" data-method="delete" class="mx-3" @click="hideMenu">
            <std-button fa-icon="fas fa-sign-out-alt" title="Log out" />
          </a>
          <a v-if="roomId >= 0" href="/rooms/" @click="hideMenu" class="mx-3">
            <std-button fa-icon="fas fa-angle-double-left" title="Leave room" />
          </a>
          <!-- <a @click="hideMenu" :href="[roomId >= 0 ? `/users/edit/?current_room_id=${roomId}` : '/users/edit/']" class="mx-3"> -->
            <std-button fa-icon="fas fa-cog" title="Settings" @click.native="$root.$emit('open-user-settings'); hideMenu();" class="mx-3" />
          <!-- </a> -->
          <!-- <std-button v-if="showSoundControls" @click.native="$root.$emit('toggle-music')" :class="['mx-3', { disabled: !sounds.musicOn }]" fa-icon="fas fa-music" title="Music" />
          <std-button v-if="showSoundControls" @click.native="$root.$emit('toggle-sound-fx')" :class="['mx-3', { disabled: !sounds.soundFxOn }]" fa-icon="fas fa-drum" title="SFX" /> -->
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    props: {
      roomId: Number,
      sounds: Object,
      showSoundControls: Boolean,
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
