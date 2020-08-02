<template>
  <div class="d-contents">
    <div class="d-flex justify-content-between">
      <h5>Codewars webhook
        <sup>
          <span v-if="settings.user.connected_webhook" class="badge badge-success">Connected</span>
          <span v-else class="badge badge-danger animated flash delay-1s">Required</span>
        </sup>
      </h5>
      <std-button
        v-if="!settings.user.connected_webhook"
        @click.native="showWebhookHelp"
        fa-icon="fas fa-question-circle"
        small>Help</std-button>
    </div>
    <div v-if="settings.user.connected_webhook">
      <small>Last call received {{ formatDate(settings.user.last_webhook_at) }}.</small>
      <span class="d-flex justify-content-center my-3">
        <std-button @click.native="$root.$emit('update-settings', { user: { connected_webhook: false, last_webhook_at: null } })" small>Reconnect the webhook</std-button>
      </span>
    </div>
    <div v-else>
      <small>Add these settings to your Codewars account in order to automatically detect when you have completed a challenge.</small>
      <div class="d-flex flex-column align-items-center justify-content-center my-3">
        
        <a href="https://www.codewars.com/users/edit#forgot_password" target="_blank">
          <std-button @click.native="$root.$emit('update-settings', { user: { connected_webhook: false, last_webhook_at: null } })" small>Open Codewars settings</std-button>
        </a>
      </div>
      <div class="form-group">
        <small>
          <label for="webhook_url" class="form-control-label w-100 text-center">Payload url</label>
          <div class="custom-tooltip clickable copyable webhook-border payload-url-color" :data-tooltip="tooltipText" @mouseleave="resetTooltip">
            <input
              @click="copyToClipboard($event)"
              type="text"
              name="webhook_url"
              class="form-control text-center"
              readonly
              :value="`https://${host}/webhook`"
            />
          </div>
          <label for="webhook_url" class="form-control-label w-100 text-center mt-3">Secret</label>
          <div class="custom-tooltip clickable copyable webhook-border secret-color" :data-tooltip="tooltipText" @mouseleave="resetTooltip">
            <input
              @click="copyToClipboard($event)"
              type="text"
              name="webhook_secret"
              class="form-control text-center"
              readonly
              :value="settings.user.webhook_secret"
            />
          </div>
        </small>
      </div>
    </div>
  </div>
</template>

<script>
import EventBus from '../../services/event_bus'

export default {
  props: {
    settings: Object,
  },
  data() {
    return {
      tooltipText: "Copy to clipboard",
      host: process.env.VUE_APP_HOST
    }
  },
  mounted() {
    EventBus.$on('cancel', this.cancel)
  },
  methods: {
    cancel() {
      this.$root.$emit('close-modal')
    },
    showWebhookHelp() {
      let height = window.screen.height / 2
      window.open('/setup-webhook', 'setup_webhook', `resizable=0,width=${height * 2},height=${height},scrollbars=0,status=0,toolbar=0,location=0`);
    },
    copyToClipboard(event) {
      event.target.select()
      document.execCommand('copy')
      this.tooltipText = 'Copied'
      if (window.getSelection) {window.getSelection().removeAllRanges();}
      else if (document.selection) {document.selection.empty();}
    },
    formatDate(dateString) {
      const date = new Date(dateString)
      const time = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:${String(date.getSeconds()).padStart(2, '0')}`
      const day = this.isSameDay(new Date, date) ? 'today' : `${date.toDateString()}`
      return `${day} at ${time}`
    },
    isSameDay(a, b) {
      return a.getFullYear() === b.getFullYear() &&
        a.getMonth() === b.getMonth() &&
        a.getDate()=== b.getDate()
    },
    resetTooltip() {
      this.tooltipText = 'Copy to clipboard'
    },
  }
}
</script>

<style>

</style>