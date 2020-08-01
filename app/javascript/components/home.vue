<template>
  <div id="home" class="vh-100">
    <div class="d-contents">
      <div id="home-logo" class="small">
        <logo />
      </div>

      <!-- <widget
      id="home-profile"
      class="grid-item animated fadeIn delay-1s"
      header-title="USR://Profile/">
      </widget> -->

      <widget
      id="public-rooms"
      class="grid-item animated fadeIn delay-1s"
      header-title="PWD://War_Rooms/">
        <div class="h-100 py-3">
          <rooms-list :rooms="publicRooms"></rooms-list>
        </div>
      </widget>

      <widget
      id="private-rooms"
      class="grid-item animated fadeIn delay-1s"
      header-title="PWD://Private_War_Rooms/">
        <div class="h-100 py-3">
          <rooms-list v-if="settings.user.admin" :rooms="privateRooms"></rooms-list>
          <div v-else class="absolute-center">
            <p>Please use the link given to you to join a private war room.</p>
          </div>
        </div>
      </widget>

      <widget
      id="home-leaderboard"
      class="grid-item animated fadeIn delay-1s"
      header-title="INFO://Instructions/">
        <h6 class="tagline mb-4"><span class="highlight-red">Codewars.</span> <span class="highlight">Multiplayer.</span></h6>
        <h4 class="highlight text-center">Instructions</h4>
        <div class="h-100 px-5 py-3 scrollable">
          <ul>
            <li class="mt-3">Make sure you are logged in to Codewars as <strong>{{ settings.user.username }}</strong></li>
            <li :class="['mt-3', { 'highlight-red': !settings.user.connected_webhook }]">Add the SpeedBattles webhook to your Codewars settings.</li>
            <li class="mt-3">Join a room and click <std-button title="Join Battle" small class="d-inline-flex"></std-button> to take part in the next challenge.</li>
            <li class="mt-3">The battle starts automatically 20 seconds after the last player has joined.</li>
            <li class="mt-3">After the countdown, Codewars will automatically open in a new tab (you first need to allow pop-ups for this website).</li>
            <li class="mt-3">Alternatively, you can click <std-button title="Launch Codewars" small class="d-inline-flex"></std-button> to open the challenge.</li>
            <li class="mt-3">At least two players need to join for a battle to start.</li>
            <li class="mt-3">You will not be able to join a battle if you already completed that challenge on Codewars.</li>
            <li class="mt-3">If you completed a challenge during a battle but it is not detected automatically, you can click on <std-button title="Completed Challenge" small class="d-inline-flex"></std-button> for SpeedBattles to fetch your results again.</li>
          </ul>
        </div>
      </widget>
    </div>
    <!-- <div v-else class="absolute-center">
      <div class="max-w-100vw d-flex justify-content-center align-items-end mb-5">
        <logo />
      </div>

      <h4 class="tagline highlight m-3 large"><span class="highlight-red animated fadeIn delay-2s">Codewars.</span> <span class="animated fadeIn delay-3s">Multiplayer.</span></h4>
      <h2 class="tagline highlight-red mb-5 large animated fadeIn delay-4s">Join the war.</h2>

      <widget
      id="home-login"
      class="animated fadeIn m-auto delay-4s"
      header-title="AUTH://credentials/">
        <div class="d-flex justify-content-around pb-4">
          <a href="/users/sign_in">
            <std-button fa-icon="fas fa-sign-in-alt" large>Log in</std-button>
          </a>
          <a href="/users/sign_up">
            <std-button fa-icon="fas fa-star-of-life" large>Sign up</std-button>
          </a>
        </div>
      </widget>
    </div> -->
  </div>
</template>

<script>
import Logo from "./shared/logo.vue";
import RoomsList from './room/rooms_list.vue'

export default {
  components: {
    Logo,
    RoomsList
  },
  props: {
    publicRooms: {
      type: Array,
      default: null
    },
    privateRooms: {
      type: Array,
      default: null
    },
    settings: {
      type: Object,
      default: _ => {}
    },
    signedIn: {
      type: Boolean,
      default: false
    }
  },
}
</script>

<style lang="scss">
  $mobile-breakpoint: 992px;

  #home {
    display: grid;
    grid-template-columns: 1fr;
    row-gap: 1em;
    padding: 1em;
  }

  .grid-item {
    max-width: 100%;
    min-height: 0;
  }

  @media screen and (min-width: $mobile-breakpoint) {
    #home {
      display: grid;
      grid-template-columns: 3fr 2fr;
      grid-template-rows: 1.5em 3fr 2fr 2fr 1.5em;
      grid-template-areas:
        "public-rooms top-right"
        "public-rooms leaderboard"
        "public-rooms leaderboard"
        "private-rooms leaderboard"
        "private-rooms bottom-left";
      column-gap: 1em;
      height: 100vh;
      padding: 3%;
    }

    #home-profile {
      grid-area: profile;
    }

    #public-rooms {
      grid-area: public-rooms;
    }

    #private-rooms {
      grid-area: private-rooms;
    }

    #home-leaderboard {
      grid-area: leaderboard;
    }
  }
</style>