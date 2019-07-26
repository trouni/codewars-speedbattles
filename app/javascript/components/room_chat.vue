<template>
  <div id="room-chat" class="widget-bg">
    <div class="widget">
      <h3 class="header">{{ title }}</h3>
      <div class="widget-body">
        <div class="flex-grow-1"></div>
        <ul class="messages scrollable" v-chat-scroll="{always: true, smooth: true}" v-if="loaded">
          <li v-for="message in sortedMessages" v-bind:class="messageClass(message)">
            <span class="author" v-if="!isAnnouncement(message)">{{  `${message.author.username}>` }}</span> <span class="content">{{ message.content }}</span>
          </li>
        </ul>
        <div id="msg-input">
          > <input class="input-field" type="text" @keyup.enter="sendMessage" v-model="input"><!-- <button class="line-height-1">Send</button> -->
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import Chat from '../services/chat'

  export default {
    props: {
      chatId: Number,
      userId: Number
    },
    data() {
      return {
        title: "Comms://Chatlogs",
        input: "",
        messages: [],
        loaded: false
      }
    },
    created() {
    },
    channels: {
      ChatChannel: {
          connected() {
            this.loadChat()
            console.log('WebSockets connected to ChatChannel.')
          },
          rejected() {},
          received(data) {
            this.messages.push(data)
            // console.log(this.messages)
          },
          disconnected() {}
      }
    },
    computed: {
      sortedMessages() {
        // return this.messages
        if (this.messages) {
          return this.messages.sort((a, b) => {
            return new Date(a.created_at) - new Date(b.created_at)
          })
        }
      }
    },
    mounted() {
        this.$cable.subscribe({ channel: 'ChatChannel', chat_id: this.chatId })
    },
    methods: {
      loadChat() {
        Chat.getMessages(this.chatId).then((response) => {
          // console.log(response)
          this.messages = response.messages
          this.loaded = true
        })
      },
      isAnnouncement(message) {
        return message.author.username === "bot"
      },
      messageClass(message) {
        return [
          'message',
          { 'bot-announcement': this.isAnnouncement(message) }
        ]
      },
      sendMessage() {
        const message = {
          chat_id: this.chatId,
          user_id: this.userId,
          content: this.input
        }
        Chat.postMessage(message, this.getToken()).then(response => {
        })
        this.input = ''
      },
      getToken() {
        return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    }
  }
</script>

<style scoped>
</style>
