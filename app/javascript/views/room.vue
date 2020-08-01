<template>
    <div id="room" :class="{ moderator: currentUserIsModerator, 'initializing': initializing }">

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
          v-if="battleInitialized && currentUser"
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
          :loading="(!usersInitialized && !battleInitialized) || battleLoading"
          :focus="focus === 'battle'"
          :settings="settings"
        />

        <room-leaderboard
          v-if="currentUser"
          class="grid-item animated fadeIn"
          :users="users"
          :room="room"
          :battle="battle"
          :battleStage="battleStage"
          :room-players="roomPlayers"
          :current-user="currentUser"
          :current-user-is-moderator="currentUserIsModerator"
          :loading="!usersInitialized || roomPlayersLoading"
          :focus="focus === 'leaderboard'"
        />

        <room-chat
          v-if="currentUser"
          class="grid-item animated fadeIn"
          :messages="chat.messages"
          :authors="chat.authors"
          :current-user="currentUser"
          :loading="!messagesInitialized"
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

export default {
  components: {
    RoomChat,
    RoomLeaderboard,
    RoomBattle,
    RoomSettings,
    UserSettings,
  },
  props: {
    announcerWindow: Object,
    battle: Object,
    battleInitialized: Boolean,
    battleJoinable: Boolean,
    battleLoading: Boolean,
    battleStage: Number,
    chat: Object,
    countdown: Number,
    currentUser: Object,
    currentUserIsModerator: Boolean,
    focus: String,
    initializing: Boolean,
    messagesInitialized: Boolean,
    readyToStart: Boolean,
    room: Object,
    roomName: String,
    roomPlayers: Array,
    roomPlayersLoading: Boolean,
    roomSettingsInitialized: Boolean,
    settings: Object,
    users: Array,
    usersInitialized: Boolean,
  },
};
</script>

<style>
</style>