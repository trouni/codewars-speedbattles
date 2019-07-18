<template>
  <div id="room-chat" class="widget">
    <h3 class="highlight">{{ title }}</h3>
    <ul>
      <li v-for="message in messages">
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
        messages: ''
      }
    },
    created() {
      // App[`chat_${this.chatId}`] = App.cable.subscriptions.create(
      //   { channel: 'ChatChannel', chat_id: this.chatId },
      //   {
      //     received: (data) => {
      //       console.log(data)
      //       // console.log("Received WebSocket Data!!!")
      //     }
      //   }
      // )
      this.loadChat()
    },
    methods: {
      loadChat() {
        Chat.getMessages(this.chatId).then(response => this.messages = response.messages)
      },
      sendMessage() {
        const message = {
          chat_id: this.chatId,
          user_id: this.userId,
          content: this.input
        }
        Chat.postMessage(message, this.getToken()).then(response => {
          this.input = ''
          this.messages.push(response)
        })
      },
      getToken() {
        return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    }
  }
</script>

<style scoped>
</style>
