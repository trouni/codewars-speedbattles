<template>
  <div class="form-inputs">
    <div class="form-group string required user_username">
      <label for="user_username" class="form-control-label string required"><strong>CodeWars username</strong> <abbr title="required">*</abbr></label>
      <input autofocus="autofocus" required="required" aria-required="true" type="text" value="" name="user[username]" id="user_username" :class="['form-control string required', { 'is-valid': validUsername }, { 'is-invalid': username && fetched && !validUsername }]" v-model="username" @blur="checkUsername" placeholder="Enter your CodeWars username">
      <small>Spaces are not allowed. <a href="https://www.codewars.com/users/edit" target="_blank">Click here</a> to see/edit your CodeWars username.</small>
      <div :class="[{ 'valid-feedback': validUsername }, { 'invalid-feedback': !validUsername }]">{{ error }}</div>
    </div>
    <div class="form-group string user_name">
      <label for="user_name" class="form-control-label"><strong>Display name</strong> <small>(optional)</small></label>
      <input autocomplete="name" aria-required="false" type="text" name="user[name]" id="user_name" class="form-control" placeholder="The name other players will see you as">
      <small>Your CodeWars username will be displayed unless you specify a display name.</small>
    </div>
    <div class="form-group password required user_password">
      <label for="user_password" class="form-control-label password required"><strong>Password</strong> <abbr title="required">*</abbr></label>
      <input autocomplete="new-password" required="required" aria-required="true" type="password" name="user[password]" id="user_password" :class="['form-control password required', { 'is-valid': password && validPassword }, { 'is-invalid': password && !validPassword }]" v-model="password" placeholder="Enter a new password.">
      <small>Doesn't need to be the same password as your CodeWars account.</small>
      <div class="invalid-feedback">6 characters minimum</div>
      <div class="valid-feedback">Looks good!</div>
    </div>
    <div class="form-group password required user_password_confirmation">
      <label for="user_password_confirmation" class="form-control-label password required"><strong>Password confirmation</strong> <abbr title="required">*</abbr></label>
      <input autocomplete="new-password" required="required" aria-required="true" type="password" name="user[password_confirmation]" id="user_password_confirmation" :class="['form-control password required', { 'is-valid': passwordCheck && validPasswordCheck }, { 'is-invalid': passwordCheck && !validPasswordCheck }]" v-model="passwordCheck" placeholder="Enter the password again for confirmation.">
      <div class="invalid-feedback">The passwords don't match.</div>
      <div class="valid-feedback">Looks good!</div>
    </div>
    <button type="submit" name="commit" :disabled="!validForm" value="Sign up" class="button large mx-auto">Sign up</button>
  </div>

</template>

<script>
export default {
  data: function () {
    return {
      username: '',
      password: '',
      passwordCheck: '',
      validUsername: null,
      fetched: false,
      error: null,
      email: `${this.username}@me.com`,
    }
  },
  computed: {
    validForm() {
      return this.validUsername && this.validPassword && this.validPasswordCheck
    },
    validPassword() {
      return this.password.length >= 6
    },
    validPasswordCheck() {
      return this.password === this.passwordCheck
    },
  },
  methods: {
    checkUsername() {
      if (this.username !== '') {
        fetch(`/api/v1/check_username?username=${this.username}`, {
        headers: {
          'content-type': 'application/json'
        }}).then(response => response.json())
        .then((response) => {
          this.fetched = true
          this.validUsername = response.valid
          this.email = `${this.username}@me.com`
          this.error = `${this.username} is ${ response.valid ? '' : 'not' } a valid CodeWars username${ response.valid ? '' : ' (case sensitive). Please enter your actual CodeWars username' }.`
        })
      }
    },
  }
}
</script>

<style scoped>
</style>
