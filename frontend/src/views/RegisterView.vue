<script setup lang="ts">
import router from '@/router';
import { ref } from 'vue';

const handleSubmit = async () => {
    const r = await fetch("http://localhost:4000/register", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(form.value)
    })

    if (r.status === 201) {
        window.alert("Registered")
        router.push("/")
    } else {
        window.alert("Error during registration...")
    }
}

const form = ref({
    user_name: "",
    email: "",
    password: "",
})

const u1 = {
    user_name: "test1",
    email: "test1@mail.com",
    password: "testuser",
}

const u2 = {
    user_name: "test2",
    email: "test2@mail.com",
    password: "testuser",
}
</script>

<template>
    <main>
        <form class="flex flex-col gap-2 p-2 w-[400px] border rounded-md" 
            @submit.prevent="() => handleSubmit()">
            <fieldset class="flex flex-col">
                <label for="username">Username</label>
                <input class="outline p-2 rounded-md"
                    type="text" id="username" v-model="form.user_name" required>
            </fieldset>
            <fieldset class="flex flex-col">
                <label for="email">Email</label>
                <input class="outline p-2 rounded-md"
                    type="email" id="email" v-model="form.email" required>
            </fieldset>
            <fieldset class="flex flex-col">
                <label for="password">Password</label>
                <input 
                    class="outline p-2 rounded-md"
                    type="password" id="password" v-model="form.password" required>
            </fieldset>
            <button 
                class="bg-slate-300 w-[100px] rounded-md shadow-md"
                type="submit">Register</button>
        </form>
        <div class="flex gap-2 p-2">
        <button 
            class="bg-slate-300 w-[100px] rounded-md shadow-md"
            @click="() => form = u1"
            type="button">Prefill User 1</button>
        <button 
            class="bg-slate-300 w-[100px] rounded-md shadow-md"
            @click="() => form = u2"
            type="button">Prefill User 2</button>
        </div>

    </main>
</template>
