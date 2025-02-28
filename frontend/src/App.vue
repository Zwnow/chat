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

const logout = () => {
    localStorage.clear()
    userStore.isAuthenticated = false
    window.location.reload()
}
</script>

<template>
  <header>

    <div class="wrapper">
      <nav v-if="!userStore.isAuthenticated" class="flex gap-2">
        <RouterLink to="/">Login</RouterLink>
        <RouterLink to="/register">Register</RouterLink>
      </nav>
      <nav v-else class="flex gap-2">
        <RouterLink to="/profile">Profile</RouterLink>
        <RouterLink to="/invites">Invites</RouterLink>
        <button @click="() => logout()">Logout</button>
      </nav>
    </div>
  </header>

  <RouterView v-if="!loading" />
</template>

