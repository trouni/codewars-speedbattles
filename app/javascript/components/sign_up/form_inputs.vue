<template>
  <div class="form-inputs">
    <div class="form-group string required user_username">

      <div class="form-group email required user_email hidden"><label for="user_email" class="form-control-label email required">Email <abbr title="required">*</abbr></label><input autocomplete="email" autofocus="autofocus" v-model="email" required="required" aria-required="true" type="email" name="user[email]" id="user_email" class="form-control string email required"></div>

      <label for="user_username" class="form-control-label string required">CodeWars username <abbr title="required">*</abbr></label>
      <input autofocus="autofocus" required="required" aria-required="true" type="text" value="" name="user[username]" id="user_username" :class="['form-control string required', { 'is-valid': validUsername }, { 'is-invalid': username && fetched && !validUsername }]" v-model="username" @blur="checkUsername" placeholder="Enter a valid CodeWars username">
      <div :class="[{ 'valid-feedback': validUsername }, { 'invalid-feedback': !validUsername }]">{{ error }}</div>
    </div>
    <div class="form-group password required user_password">
      <label for="user_password" class="form-control-label password required">Password <abbr title="required">*</abbr></label>
      <input autocomplete="new-password" required="required" aria-required="true" type="password" name="user[password]" id="user_password" :class="['form-control password required', { 'is-valid': password && validPassword }, { 'is-invalid': password && !validPassword }]" v-model="password">
      <div class="invalid-feedback">6 characters minimum</div>
      <div class="valid-feedback">Looks good!</div>

    </div>
    <div class="form-group password required user_password_confirmation">
      <label for="user_password_confirmation" class="form-control-label password required">Password confirmation <abbr title="required">*</abbr></label>
      <input autocomplete="new-password" required="required" aria-required="true" type="password" name="user[password_confirmation]" id="user_password_confirmation" :class="['form-control password required', { 'is-valid': passwordCheck && validPasswordCheck }, { 'is-invalid': passwordCheck && !validPasswordCheck }]" v-model="passwordCheck">
      <div class="invalid-feedback">Doesn't match the previous password.</div>
      <div class="valid-feedback">Looks good!</div>
    </div>
    <input type="submit" name="commit" :disabled="!validForm" value="Sign up" class="button">
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
          this.error = `${this.username} is ${ response.valid ? '' : 'not' } a valid CodeWars username${ response.valid ? '' : '(case sensitive)' }.`
        })
      }
    },
  }
}
</script>

<style scoped>
</style>
