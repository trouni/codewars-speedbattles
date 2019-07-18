export default {
  headers (token) {
    return {
        'content-type': 'application/json',
        'X-User-Email': 'trouni@me.com',
        'X-User-Token': 'bRp8e6d8s6RPt1SPQvyj',
        'X-CSRF-Token': token
      }
  },
  getMessages (chatId) {
    return fetch(`/api/v1/chats/${chatId}`).then(response => response.json());
  },
  postMessage (message, token) {
    return fetch(`/api/v1/messages`, {
      method: "POST",
      headers: this.headers(token),
      body: JSON.stringify(message)
    }).then(response => response.json());
  }
}
