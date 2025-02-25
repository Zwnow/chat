<script setup lang="ts">
import { ref } from 'vue';
import { useUserStore } from '@/stores/userStore';
import router from '@/router';
const userStore = useUserStore();
const handleSubmit = async () => {
    const r = await fetch("http://localhost:4000/login", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(form.value)
    })

    if (r.status === 200) {
        const data = await r.json();
        userStore.token = data.token;
        userStore.userID = data.userID;
        userStore.isAuthenticated = true;
        localStorage.setItem('token', data.token);
        router.push("/profile");
    }
}

const form = ref({
    email: "",
    password: "",
})

</script>

<template>
    <main>
        <form class="flex flex-col gap-2 p-2 w-[400px] border rounded-md" 
            @submit.prevent="() => handleSubmit()">
            <fieldset class="flex flex-col">
                <label for="email">Email</label>
                <input class="outline p-2 rounded-md"
                    type="text" id="email" v-model="form.email" required>
            </fieldset>
            <fieldset class="flex flex-col">
                <label for="password">Password</label>
                <input 
                    class="outline p-2 rounded-md"
                    type="password" id="password" v-model="form.password" required>
            </fieldset>
            <button 
                class="bg-slate-300 w-[100px] rounded-md shadow-md"
                type="submit">Login</button>
        </form>
    </main>
</template>
