export default {
  getRoom (id) {
    return fetch(`/api/v1/rooms/${id}`)
      .then(response => response.json())
  }
}
