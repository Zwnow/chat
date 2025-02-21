<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router';
import { onMounted, ref } from 'vue';
import { useUserStore } from '@/stores/userStore';
import router from './router';

const userStore = useUserStore();
const loading = ref(true);
onMounted(async () => {
    loading.value = true;
    const token = localStorage.getItem('token');
    if (token !== null) {
        userStore.token = token;
        await userStore.authenticate();

        if (userStore.isAuthenticated) {
            router.push("/profile");
        }
    }
    loading.value = false;
});
</script>

<template>
  <header>

    <div class="wrapper">
      <nav>
        <RouterLink to="/">Home</RouterLink>
        <RouterLink to="/register">Register</RouterLink>
      </nav>
    </div>
  </header>

  <RouterView v-if="!loading" />
</template>

<style scoped>

</style>
