export default {
  getRoom (id) {
    return fetch(`/api/v1/rooms/${id}`)
      .then(response => response.json());
  },

  getChallenge (input) {
    const id = this.parseChallengeInput(input).challengeIdSlug
    return fetch(`/api/v1/challenges/${id}`)
      .then(response => response.json());
  },

  parseChallengeInput (input) {
    const urlRegex = /^(https:\/\/)?www\.codewars\.com\/kata\/(?<challengeIdSlug>.+)\/train\/(?<language>.+)$/;
    const matchData = input.match(urlRegex);
    if (matchData) {
      return {
        "challengeIdSlug": matchData.groups.challengeIdSlug,
        "language": matchData.groups.language
      };
    } else {
      return {
        "challengeIdSlug": input,
        "language": null
      }
    }
  },

  postBattle (room_id, attrs) {
    return fetch(`/api/v1/rooms/${room_id}/battles/`, {
      method: "POST",
      headers: {
        'content-type': 'application/json'
      },
      body: JSON.stringify(attrs)
    }).then(response => response.json());
  }
}
