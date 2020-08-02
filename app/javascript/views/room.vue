<template>
    <div id="room" :class="{ moderator: currentUserIsModerator, 'initializing': initializing }">

      <modal
        v-if="focus === 'webhook' && !initializing"
        id="webhook-instructions"
        :controls="{ hide: webhookRequired, submit: null, cancel: 'Later' }"
        title="SETUP://Connect_Webhook">
        <template>
          <div class="py-3">
            <webhook-instructions :settings="settings" />
          </div>
        </template>
      </modal>

      <widget
        v-if="!signedIn"
        id="join-fight"
        class="seek-attention d-flex align-items-center justify-content-center animated slideInDown delay-2s"
        :focus="!focus"
        @click.native="$root.$emit('toggle-settings')"
        >
        <std-button fa-icon="fas fa-radiation">Join the fight</std-button>
      </widget>

      <widget
        id="room-announcer"
        class="grid-item animated fadeIn"
        :header-title="`PWD://War_Room/${roomName.replace(/\s/g, '_')}`"
        :focus="focus === 'announcer'">
        <div class="d-flex align-items-center justify-content-center h-100">
          <span
            :class="['announcer mt-3', 'text-center', announcerWindow.status]"
            v-html="announcerWindow.content"
          ></span>
        </div>
      </widget>

      <div v-if="roomSettingsInitialized" class='d-contents'>
        <room-battle
          id="room-battle"
          class="grid-item animated fadeIn"
          :battle="battle"
          :battleStage="battleStage"
          :users="users"
          :room="room"
          :countdown="countdown"
          :battle-joinable="battleJoinable"
          :current-user="currentUser"
          :current-user-is-moderator="currentUserIsModerator"
          :ready-to-start="readyToStart"
          :loading="battleLoading"
          :focus="focus === 'battle'"
          :settings="settings"
        />

        <room-leaderboard
          class="grid-item animated fadeIn"
          :users="users"
          :room="room"
          :battle="battle"
          :battleStage="battleStage"
          :room-players="roomPlayers"
          :current-user="currentUser"
          :current-user-is-moderator="currentUserIsModerator"
          :loading="usersLoading || roomPlayersLoading"
          :focus="focus === 'leaderboard'"
        />

        <room-chat
          class="grid-item animated fadeIn"
          :messages="chat.messages"
          :authors="chat.authors"
          :current-user="currentUser"
          :loading="messagesLoading"
          :focus="focus === 'chat'"
          :settings="settings"
        />
      </div>
    </div>
</template>

<script>
import Vue from 'vue/dist/vue.esm'
import RoomChat from "../components/room/room_chat";
import RoomLeaderboard from "../components/room/room_leaderboard";
import RoomBattle from "../components/room/room_battle";
import RoomSettings from "../components/settings/room_settings";
import UserSettings from "../components/settings/user_settings";
import WebhookInstructions from "../components/settings/webhook_instructions";

export default {
  watch: {
    settings: {
      handler: function(settings) {
        if (this.signedIn && !settings.user.connected_webhook && !this.focus) {
          this.$root.$emit('set-focus', "webhook")
        } else if (settings.user.connected_webhook && this.focus === 'webhook') {
          this.$root.$emit('speak', 'Webhook, connected.', {
            fx: 'interface',
            fxPlayAt: 'start',
            fxVolume: 0.5,
            interrupt: false
          })
          setTimeout(_ => {
            if (settings.user.connected_webhook) this.$root.$emit('close-modal')
          }, 3000)
        }
      },
      deep: true,
      immediate: true
    },
  },
  components: {
    RoomChat,
    RoomLeaderboard,
    RoomBattle,
    RoomSettings,
    UserSettings,
    WebhookInstructions
  },
  props: {
    announcerWindow: Object,
    battle: Object,
    battleJoinable: Boolean,
    battleLoading: Boolean,
    battleStage: Number,
    chat: Object,
    countdown: Number,
    currentUser: Object,
    currentUserIsModerator: Boolean,
    focus: String,
    initializing: Boolean,
    messagesLoading: Boolean,
    readyToStart: Boolean,
    room: Object,
    roomName: String,
    roomPlayers: Array,
    roomPlayersLoading: Boolean,
    roomSettingsInitialized: Boolean,
    settings: Object,
    signedIn: Boolean,
    users: Array,
    usersLoading: Boolean,
    webhookRequired: {
      type: Boolean,
      default: true
    }
  },
};
</script>

<style lang="scss">
  #join-fight {
    position: absolute;
    top: -2.1em;
    right: 10%;
    z-index: 10;
    transition: top 0.5s cubic-bezier(0.075, 0.82, 0.165, 1);
    .widget {
      padding: 0.2em 3em;
      min-height: unset;
    }
    .widget, .widget-bg {
      clip-path: polygon(0 0, 100% 0, 100% 1.5em, 100% calc(100% - 1.5em), calc(100% - 1.5em) 100%, 1.5em 100%, 0 calc(100% - 1.5em));
    }
    &:hover {
      top: -1.8em;
      border-color: white;
    }
  }
</style>