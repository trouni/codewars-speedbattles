<template>
  <widget id="room-chat" :header-title="title" :loading="loading" :focus="focus">
    <div class="flex-grow-1"></div>
    <ul class="messages scrollable" v-chat-scroll="{always: true, smooth: true, scrollonremoved:true}" ref="messages">
      <li v-for="message in sortedMessages" v-bind:class="messageClass(message)" :key="message.id">
        <div v-if="!isAnnouncement(message)">
          <span class="message-header d-flex">
            <span class="author" :title="message.author.username">{{ message.author.name || message.author.username }}</span>
            <div class="sent-at" v-html="formatMessageDate(message.created_at)" />
          </span>
          <chat-message :content="message.content" class="content" />
        </div>
        <div v-else>
          <span class="content" v-html="displayMsg(message)" />
        </div>
      </li>
    </ul>
    <template v-slot:controls>
      <div id="msg-input" :class="['with-prompt', { multiline: multilineInput, code: codeInput}]" ref="input">
        <textarea
          id="msg-textarea"
          :rows="inputMinRows"
          placeholder='Send a message...'
          @input="updateTextAreaRows"
          @keydown.enter="sendMessage"
          @keydown.tab="addTabCharacter"
          @keyup.`="prefillBlockLang"
          v-model="input"
          ref="textarea"
          v-focus
        ></textarea>
        <a v-if="settings.room.voice_chat_url" :href="settings.room.voice_chat_url" target="_blank">
          <std-button small fa-icon="fas fa-microphone" title="Join voice chat" :class="['join-call animated flipInX', { 'flipOutX': input }]" />
        </a>
      </div>
    </template>
  </widget>
</template>

<script>
  export default {
    props: {
      messages: Array,
      authors: Array,
      currentUser: Object,
      loading: Boolean,
      initializing: Boolean,
      focus: Boolean,
      settings: Object,
    },
    components: {
      ChatMessage: () => import('./chat/message'),
    },
    data() {
      return {
        title: "Comms://Chatlogs",
        input: "",
        inputRowHeight: 0,
        inputMinRows: 2,
        inputMaxRows: 17,
        submitHint: null,
        focusOnInput: false,
      }
    },
    computed: {
      sortedMessages() {
        if (this.messages) {
          return this.messages.sort((a, b) => {
            return new Date(a.created_at) - new Date(b.created_at)
          })
          .filter(message => this.hasContent(message))
        }
      },
      inputLines() {
        const newLines = this.input.match(/(\r\n|\r|\n)/gm)
        return newLines ? newLines.length + 1 : 1
      },
      multilineInput() {
        const textarea = this.$refs.textarea
        return this.inputLines > 1 || this.codeInput
      },
      codeInput() {
        return this.input.match(/^```\w*$/m) !== null
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
      this.getUserOS()
      this.$refs.input.setAttribute('data-submit-hint', `Send: ${this.submitHint}`)
      setTimeout(_ => this.autoScrollToLastMessage(), 500)
    },
    methods: {
      getUserOS() {
        if (navigator.appVersion.indexOf("Win") != -1) this.submitHint = "[Ctrl]+[Enter]"; 
        if (navigator.appVersion.indexOf("Mac") != -1) this.submitHint = "[⌘]+[Enter]";
        if (navigator.appVersion.indexOf("X11") != -1) this.submitHint = "[Ctrl]+[Enter]"; 
        if (navigator.appVersion.indexOf("Linux") != -1) this.submitHint = "[Ctrl]+[Enter]";
      },
      updateTextAreaRows() {
        const textarea = this.$refs.textarea
        const previousRows = textarea.rows
        const atBottom = this.messagesScrolledToBottom()
        var minRows = this.inputMinRows|0
        textarea.rows = minRows;
        const extraRows = Math.ceil((textarea.scrollHeight - this.baseScrollHeight) / this.inputRowHeight)
        textarea.rows = Math.min(minRows + extraRows, this.inputMaxRows);
        if (textarea.rows !== previousRows && atBottom) this.autoScrollToLastMessage()
      },
      getInputRowHeight() {
        const textarea = this.$refs.textarea
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
        return `${this.replaceUsername(msg.content)}<div class="sent-at">${this.formatMessageDate(msg.created_at)}</div>`
      },
      isAnnouncement(message) {
        return !message.author.username || message.author.username === "bot"
      },
      messageClass(message) {
        return [
          'message',
          { 'bot-announcement animated fadeIn': this.isAnnouncement(message) },
          { 'user-message': !this.isAnnouncement(message) }
        ]
      },
      messagesScrolledToBottom() {
        const messages = this.$refs.messages;
        return messages.scrollTop >= messages.scrollHeight - messages.clientHeight - 50;
      },
      autoScrollToLastMessage() {
        const messages = this.$refs.messages;
        messages.scrollTop = messages.scrollHeight;
      },
      sendMessage(e) {
        if (e.shiftKey) return
        if (this.multilineInput && !e.metaKey && !e.ctrlKey) return

        e.preventDefault()
        this.$root.$emit('send-chat-message', this.input );
        this.input = ''
        this.$refs.textarea.value = this.input
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
      prefillBlockLang(e) {
        if (this.input === '```') {
          const lang = this.settings.room.language
          e.target.value += lang + '\r\n'
          if (!lang) e.target.selectionStart = 3
          e.target.selectionEnd =  e.target.selectionStart + lang.length
        }
      },
      formatMessageDate(sentDate) {
        const date = new Date(sentDate)
        const time = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
        // return this.isSameDay(new Date, date) ? time : `<span class="date">${date.toDateString()} at&nbsp;</span><span>${time}</span>`
        return `<span class="date">${date.toDateString()} at&nbsp;</span><span>${time}</span>`
      },
      isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear() &&
          a.getMonth() === b.getMonth() &&
          a.getDate()=== b.getDate()
      },
      hasContent(message) {
        return message.content.split(/^```\w*$/gm)
                              .filter(block => _.trim(block))
                              .length > 0
      }
    }
  }
</script>

<style scoped>
.join-call {
  position: absolute;
  bottom: 0.5em;
  right: 1em;
  z-index: 10;
}
</style>
