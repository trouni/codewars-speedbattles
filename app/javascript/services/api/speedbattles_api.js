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

  postInvite (battle_id, user_id) {
    return fetch(`/api/v1/battles/${battle_id}/invite?user_id=${user_id}`)
      .then(response => response.json());
  },

  deleteInvite (battle_id, user_id) {
    return fetch(`/api/v1/battles/${battle_id}/invite?user_id=${user_id}`, {
      method: "DELETE"
    }).then(response => response.json());
  },

  inviteAll (battle_id) {
    return fetch(`/api/v1/battles/${battle_id}/invite_all`)
      .then(response => response.json());
  },

  postBattle (room_id, attrs) {
    return fetch(`/api/v1/rooms/${room_id}/battles`, {
      method: "POST",
      headers: {
        'content-type': 'application/json'
      },
      body: JSON.stringify(attrs)
    }).then(response => response.json());
  },

  deleteBattle (battle_id) {
    return fetch(`/api/v1/battles/${battle_id}`, {
      method: "DELETE"
    }).then(response => response.json());
  }
}
