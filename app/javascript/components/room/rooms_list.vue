<template>
  <div class="fixed-header">
    <table class="rooms console-table h-100">
      <thead>
        <tr>
          <th scope="col" style="width: 40%;"><span class="data">NAME</span></th>
          <th scope="col" style="width: 10%;"><span class="data">PLAYERS</span></th>
          <th scope="col" style="width: 20%;"><span class="data">LANGUAGE</span></th>
          <th scope="col" style="width: 30%;"><span class="data">DIFFICULTY</span></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(room, index) in rooms" :class="['animated fadeInUp', 'highlight' ]" :title="`${room.name}`" :key="room.id">
          <th scope="row">
            <span class="data">
              <a :href="`/rooms/${room.id}`" class='highlight'>
                {{ room.name }}
              </a>
            </span>
          </th>
          <td>
            <span class="data">{{ room.users_count }} / {{ room.max_users ? room.max_users : '∞' }}</span>
          </td>
          <td>
            <span class="data">{{ room.languages[0] }}</span>
          </td>
          <td>
            <span v-if="room.katas.ranks.length > 1" class="data kata-ranks align-items-center">
              <rank-hex
                :rank="room.katas.ranks[0]"
                class="small m-1"
              /> ⇀ <rank-hex
                :rank="room.katas.ranks[room.katas.ranks.length - 1]"
                class="small m-1"
              />
            </span>
            <span v-else class="data kata-ranks align-items-center">
              <rank-hex
                :rank="room.katas.ranks[0]"
                class="small m-1"
              />
            </span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
export default {
  props: {
    rooms: Array,
  },
  data() {
    return {
      
    }
  }
}
</script>

<style>

</style>