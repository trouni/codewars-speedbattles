<template>
  <div class="main-logo">
    <div class="codewars-logo mr-3 animated slideInRight">
      <img src="/images/codewars_logo.png" class="animated flipInY fast"/>
    </div>
    <h1 class="main-title mx-3">
      <div class="highlight speed animated lightSpeedIn">
        <div>Speed</div>
      </div>
      <div class="battles highlight-red animated flipInY ">
        <div class="animated pulse delay-1s slower">Battles</div>
      </div>
    </h1>
  </div>
</template>

<script>
export default {

}
</script>

<style lang="scss">
  .main-logo {
    animation-duration: 0.2s;
    display: flex;
    justify-content: center;
    align-content: center;
    transform: scale(0.7);

    $body-font: "Kanit", "Helvetica", "sans-serif";
    
    .main-title {
      .speed {
        font-size: 2.1em;
        font-family: $body-font;
        text-transform: uppercase;
      }
      .battles {
        font-size: 1.75em;
        text-transform: uppercase;
        font-weight: bold;
        animation-duration: 0.4s;
        animation-delay: 1s;
        div {
          letter-spacing: 0.03em;
        }
      }
    }

    .codewars-logo {
      display: flex;
      align-items: center;
      img {
        height: 136px;
      }
    }

    // Animation delays
    .codewars-logo, .main-title .speed {
      animation-duration: 0.4s;
      animation-delay: 0.6s;
    }
  }

  .tagline {
    text-align: center;
    position: relative;
  }

  @media screen and (min-width: 576px) {
    .main-logo {
      transform: scale(0.7);
    }
  }

  @media screen and (min-width: 768px) {
    .main-logo {
      transform: scale(1);
    }
  }
</style>