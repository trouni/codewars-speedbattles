<template>
  <span v-if="rank" class="rank-hex d-inline-block">
    <div :class="['small-hex', rankColor[rank]]">
      <div class="inner-small-hex">
        <span v-html="rankName[rank]" />
      </div>
    </div>
  </span>
</template>

<script>
export default {
  props: {
    rank: String,
  },
  data() {
    return {
      rankColor: {
        '-8': 'white-rank',
        '-7': 'white-rank',
        '-6': 'yellow-rank',
        '-5': 'yellow-rank',
        '-4': 'blue-rank',
        '-3': 'blue-rank',
        '-2': 'purple-rank',
        '-1': 'purple-rank',
        '1': 'black-rank',
        '2': 'black-rank',
        '3': 'black-rank',
        '4': 'black-rank',
      },
      rankName: {
        '-8': '8 kyu',
        '-7': '7 kyu',
        '-6': '6 kyu',
        '-5': '5 kyu',
        '-4': '4 kyu',
        '-3': '3 kyu',
        '-2': '2 kyu',
        '-1': '1 kyu',
        '1': '1 dan',
        '2': '2 dan',
        '3': '3 dan',
        '4': '4 dan',
      },
    }
  }
};
</script>

<style lang='scss' scoped>
.rank-hex {
  vertical-align: bottom;
  opacity: 0.8;
}
.small-hex {
  height: 26px;
  width: 34px;
  // background-color: #bb432c;
  // color: #131414;
  position: relative;
  margin-right: 8px;
  margin-left: 8px;
  text-align: center;
  line-height: 26px;
  // font-weight: bold;
  z-index: 1;
  text-shadow: none;
  line-height: 28px;
  font-size: 12px;
  &:before {
    content: " ";
    width: 0;
    height: 0;
    border-right: 8px solid #bb432c;
    border-top: 13px solid transparent;
    border-bottom: 13px solid transparent;
    position: absolute;
    left: -8px;
    z-index: 0;
  }
  &:after {
    content: "";
    width: 0;
    position: absolute;
    right: -8px;
    top: 0;
    border-left: 8px solid #bb432c;
    border-top: 13px solid transparent;
    border-bottom: 13px solid transparent;
    z-index: 0;
  }
  span {
    z-index: 2;
    position: relative;
    font-size: 11px;
    line-height: 22px;
    font-family: "Lato", "Helvetica Neue", "Helvetica", Arial, sans-serif;
    white-space: nowrap;
    letter-spacing: 0;
  }
}

.inner-small-hex {
  height: 22px;
  width: 32px;
  background-color: #181919;
  // color: #131414;
  position: relative;
  margin-right: 6px;
  margin-left: 6px;
  text-align: center;
  line-height: 22px;
  z-index: 1;
  text-shadow: none;
  margin-left: 1px;
  color: #efefef;
  top: 2px;
  font-size: 11px;
  // color: #b1361e;
  &:before {
    content: " ";
    width: 0;
    height: 0;
    border-right: 6px solid #181919;
    border-top: 11px solid transparent;
    border-bottom: 11px solid transparent;
    position: absolute;
    left: -6px;
    z-index: 0;
  }
  &:after {
    content: "";
    width: 0;
    position: absolute;
    right: -6px;
    top: 0;
    border-left: 6px solid #181919;
    border-top: 11px solid transparent;
    border-bottom: 11px solid transparent;
    z-index: 2;
  }
}
.blue-rank {
  background-color: #3c7ebb;
  color: rgba(20, 20, 20, 0.7);
  &:before {
    border-right-color: #3c7ebb;
  }
  &:after {
    border-left-color: #3c7ebb;
  }
  .inner-small-hex {
    color: #3c7ebb;
  }
}
.purple-rank {
  background-color: #866cc7;
  color: rgba(20, 20, 20, 0.7);
  &:before {
    border-right-color: #866cc7;
  }
  &:after {
    border-left-color: #866cc7;
  }
  .inner-small-hex {
    color: #866cc7;
  }
}
.yellow-rank {
  background-color: #ecb613;
  color: rgba(20, 20, 20, 0.7);
  &:before {
    border-right-color: #ecb613;
  }
  &:after {
    border-left-color: #ecb613;
  }
  .inner-small-hex {
    color: #ecb613;
  }
}
.white-rank {
  background-color: #e6e6e6;
  color: rgba(20, 20, 20, 0.7);
  &:before {
    border-right-color: #e6e6e6;
  }
  &:after {
    border-left-color: #e6e6e6;
  }
  .inner-small-hex {
    color: #e6e6e6;
  }
}
.black-rank {
  background-color: #555;
  color: #fff;
  &:before {
    border-right-color: #555;
  }
  &:after {
    border-left-color: #555;
  }
  .inner-small-hex {
    color: #999;
  }
}
</style>