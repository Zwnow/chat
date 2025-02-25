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
    </main>
</template>
