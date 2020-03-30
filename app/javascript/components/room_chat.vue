<template>
  <div id="room-chat" class="widget-bg w-100">
    <div class="widget">
      <h3 class="header">{{ title }}</h3>
      <div class="widget-body">
        <div class="flex-grow-1"></div>
        <ul class="messages scrollable" v-chat-scroll="{always: true, smooth: true}">
          <li v-for="message in sortedMessages" v-bind:class="messageClass(message)">
            <span class="author" v-if="!isAnnouncement(message)" :title="message.author.username">{{ message.author.name || message.author.username }}></span>
            <span class="content" v-if="!isAnnouncement(message)">{{displayMsg(message.content)}}</span>
            <span class="content" v-else v-html="displayMsg(message.content)" :title="message.created_at"></span>
          </li>
        </ul>
        <div id="msg-input" :class="['d-flex', { multiline: multilineInput}]">
          <textarea
            id="msg-textarea"
            class='autoExpand input-field flex-grow-1 text-white'
            :rows="inputMinRows"
            placeholder='Message everyone...'
            @input="updateTextAreaRows"
            @keydown.enter="sendMessage"
            @keydown.tab="addTabCharacter"
            v-model="input"
          ></textarea>
          <!-- <span class="d-flex">{{ currentUser.name || currentUser.username }}></span><input class="input-field flex-grow-1" type="text" @keyup.enter="sendMessage" v-model="input" placeholder="Type your message here..."> -->
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
        input: "",
        inputRowHeight: 0,
        inputMinRows: 2,
        inputMaxRows: 17,
      }
    },
    computed: {
      sortedMessages() {
        if (this.messages) {
          return this.messages.sort((a, b) => {
            return new Date(a.created_at) - new Date(b.created_at)
          })
        }
      },
      inputLines() {
        const newLines = this.input.match(/(\r\n|\r|\n)/gm)
        return newLines ? newLines.length + 1 : 1
      },
      multilineInput() {
        const codeFenceExists = this.input.match(/^```$/m) !== null
        return this.inputLines > 1 || codeFenceExists
      },
      baseScrollHeight() {
        return this.inputMinRows * this.inputRowHeight
      },
    },
    watch: {
      multilineInput: function() {
        this.inputMinRows = this.multilineInput ? 3 : 2
        this.updateTextAreaRows()
      },
    },
    mounted() {
      this.getInputRowHeight()
    },
    methods: {
      updateTextAreaRows() {
        const textarea = document.getElementById('msg-textarea')
        const previousRows = textarea.rows
        const atBottom = this.messagesScrolledToBottom()
        var minRows = this.inputMinRows|0
        textarea.rows = minRows;
        const extraRows = Math.ceil((textarea.scrollHeight - this.baseScrollHeight) / this.inputRowHeight)
        textarea.rows = Math.min(minRows + extraRows, this.inputMaxRows);
        if (textarea.rows !== previousRows && atBottom) this.autoScrollToLastMessage()
      },
      getInputRowHeight() {
        const textarea = document.getElementById('msg-textarea')
        const storedInput = textarea.value
        textarea.value = ''
        this.inputRowHeight = textarea.scrollHeight / this.inputMinRows
        textarea.value = storedInput
      },
      replaceUsername(str) {
        let handles = str.match(/@\{(?<username>.+?)\}/g)
        if (!handles) return str

        handles = handles.filter((a, b) => handles.indexOf(a) === b)
        handles.forEach((handle) => {
          const username = handle.match(/@\{(?<name>.+?)\}/).groups.name
          const userIndex = this.authors.findIndex((author) => author.username === username);
          const author = userIndex >= 0 ? `<span class="highlight" title="${username}">${this.authors[userIndex].name}</span>` : username
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
          { 'bot-announcement notification animated fadeIn': this.isAnnouncement(message) }
        ]
      },
      messagesScrolledToBottom() {
        const messages = document.querySelector(".messages");
        return messages.scrollTop >= messages.scrollHeight - messages.clientHeight - 50;
      },
      autoScrollToLastMessage() {
        const messages = document.querySelector(".messages");
        messages.scrollTop = messages.scrollHeight;
      },
      sendMessage(e) {
        if (e.shiftKey) return
        if (this.multilineInput && !e.metaKey && !e.ctrlKey) return

        e.preventDefault()
        this.$root.$emit('send-chat-message', this.input );
        this.input = ''
        document.getElementById('msg-textarea').value = this.input
        this.updateTextAreaRows()
      },
      addTabCharacter(e) {
        e.preventDefault()
        // const tabCharacter = '\t'
        const tabCharacter = '  ' // use two spaces
        // get caret position/selection
        var val = e.target.value,
            start = e.target.selectionStart,
            end = e.target.selectionEnd;

        // set textarea value to: text before caret + tab + text after caret
        e.target.value = val.substring(0, start) + tabCharacter + val.substring(end);

        // put caret at right position again
        e.target.selectionStart = e.target.selectionEnd = start + tabCharacter.length;
      },
    }
  }
</script>

<style scoped>
</style>
