<template>
  <div id="room-chat" class="widget-bg w-100">
    <div class="widget">
      <h3 class="header">{{ title }}</h3>
      <div class="widget-body">
        <div class="flex-grow-1"></div>
        <ul class="messages scrollable" v-chat-scroll="{always: true, smooth: true}">
          <li v-for="message in sortedMessages" v-bind:class="messageClass(message)">
            <span class="author" v-if="!isAnnouncement(message)" :title="message.author.username">{{ message.author.name || message.author.username }}></span> <span class="content" v-html="displayMsg(message.content)"></span>
          </li>
        </ul>
        <div id="msg-input" class="d-flex">
          <span class="d-flex">{{ currentUser.name || currentUser.username }}></span><input class="input-field flex-grow-1" type="text" @keyup.enter="sendMessage" v-model="input" placeholder="Type your message here...">
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    props: {
      messages: Array,
      authors: Array,
      currentUserName: String,
      currentUser: Object,
    },
    data() {
      return {
        title: "Comms://Chatlogs",
        input: ""
      }
    },
    computed: {
      sortedMessages() {
        if (this.messages) {
          return this.messages.sort((a, b) => {
            return new Date(a.created_at) - new Date(b.created_at)
          })
        }
      }
    },
    methods: {
      replaceUsername(str) {
        let handles = str.match(/@\{(?<username>.+?)\}/g)
        if (!handles) return str

        handles = handles.filter((a, b) => handles.indexOf(a) === b)
        handles.forEach((handle) => {
          const username = handle.match(/@\{(?<name>.+?)\}/).groups.name
          const userIndex = this.authors.findIndex((author) => author.username === username);
          const author = userIndex >= 0 ? `<span class="highlight" title="${username}">${this.authors[userIndex].name}</span>` : `@${username}`
          str = str.replace(handle, author)
        })
        return str
      },
      displayMsg(msg) {
        return this.replaceUsername(msg)
      },
      isAnnouncement(message) {
        return !message.author.username || message.author.username === "bot"
      },
      messageClass(message) {
        return [
          'message',
          { 'bot-announcement': this.isAnnouncement(message) }
        ]
      },
      sendMessage() {
        this.$root.$emit('send-chat-message', this.input );
        this.input = ''
      },
    }
  }
</script>

<style scoped>
</style>
