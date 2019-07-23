<template>
  <div id="room-chat" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <ul class="messages" v-chat-scroll="{always: true, smooth: true}" v-if="loaded">
      <li v-for="message in sortedMessages" v-bind:class="messageClass(message)">
        {{ `${message.author.username} > ${message.content}` }}
      </li>
    </ul>
    <input type="text" @keyup.enter="sendMessage" v-model="input">
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
        title: "Chat",
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
        return this.messages.sort((a, b) => {
          return new Date(a.created_at) - new Date(b.created_at)
        })
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
      announcement(message) {
        return message.author.username === "bot"
      },
      messageClass(message) {
        return [
          'message',
          { 'bot-announcement': this.announcement(message) }
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
  .messages {
    overflow: scroll;
    height: 90%;
  }

  .bot-announcement {
    font-style: italic;
    opacity: 0.5;
  }
</style>
