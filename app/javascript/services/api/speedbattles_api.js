export default {
  getRoom (room_id) {
    return fetch(`/api/v1/rooms/${room_id}`)
      .then(response => response.json());
  },

  getRoomUsers (room_id) {
    return fetch(`/api/v1/rooms/${room_id}/users`)
      .then(response => response.json());
  },

  getChallenge (input) {
    const id = this.parseChallengeInput(input).challengeIdSlug
    return fetch(`/api/v1/challenges/${id}`)
      .then(response => response.json());
  },

  getLeaderboard (room_id) {
    return fetch(`/api/v1/rooms/${room_id}/leaderboard`)
      .then(response => response.json());
  },

  parseChallengeInput (input) {
    const urlRegex = /^(https:\/\/)?www\.codewars\.com\/kata\/(?<challengeIdSlug>.+?)\/?(train\/(?<language>.+))?$/;
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

  invitation (battle_id, action, user_id = null, ) {
    return fetch(`/api/v1/battles/${battle_id}/invitation?${user_id ? `user_id=${user_id}&` : ''}perform=${action}`)
      .then(response => response);
  },

  getBattle (battle_id) {
    return fetch(`/api/v1/battles/${battle_id}`)
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
  },

  updateBattleStatus (battle_id, action, countdown = 10) {
    return fetch(`/api/v1/battles/${battle_id}/launch?perform=${action}&countdown=${countdown}`)
      .then(response => response.json());
  },

  getBattleResults (battle_id) {
    return fetch(`/api/v1/battles/${battle_id}/results`)
      .then(response => response.json());
  },

  fetchChallenges (user_id, battle_id) {
    return fetch(`/api/v1/users/${user_id}/fetch_data?battle_id=${battle_id}`)
      .then(response => response.json());
  },
}
