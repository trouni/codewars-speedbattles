<template>
  <form action="/users/sign_in" class="w-100" ref="form" method="post" accept-charset="UTF-8" autofocus>
    <div class="form-inputs">
      <input name="utf8" type="hidden" value="✓">
      <input type="hidden" name="authenticity_token" :value="csrfToken">
      <div class="form-group string optional user_username">
        <!-- <label for="user_username" class="form-control-label string optional d-block">Username</label> -->
        <input
          type="text"
          name="user[username]"
          id="user_username"
          placeholder="Username"
          @keydown.enter="$refs.form.submit()"
          autofocus
          autocomplete="false"
          class="w-100">
      </div>
      <div class="form-group password optional user_password">
        <!-- <label for="user_password" class="form-control-label password optional d-block">Password</label> -->
        <input type="password" placeholder="Password" name="user[password]" id="user_password" @keydown.enter="$refs.form.submit()" class="w-100">
      </div>
      <div class="form-check">
        <input name="user[remember_me]" type="hidden" value="0">
        <input type="checkbox" value="1" checked="checked" name="user[remember_me]" id="user_remember_me" class="form-check-input boolean optional">
        <label for="user_remember_me" class="form-check-label boolean optional">Remember me</label>
      </div>
      <std-button @click.native="$refs.form.submit()" fa-icon="fas fa-sign-in-alt" class="m-auto" large>Log in</std-button>
    </div>
  </form>
</template>

<script>
export default {
  data() {
    return {
      csrfToken: document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    }
  }
}
</script>

<style>

</style>