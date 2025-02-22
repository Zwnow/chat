<script setup lang="ts">
import { useUserStore } from "@/stores/userStore";
import { onMounted, ref } from "vue";

const userStore = useUserStore();
const loading = ref(true);
const hasError = ref(false);
onMounted(async () => {
    loading.value = true;
    try {
        await userStore.getChatrooms();
    } catch(e) {
        hasError.value = true;
    }
    loading.value = false;
})

const currentConnection = ref<WebSocket|null>(null);
const connect = async (chatroom: string) => {
    if (currentConnection.value !== null) {
        currentConnection.value.close();
    }
    currentConnection.value = new WebSocket(`ws://localhost/ws?chatroom=${chatroom}&token=${userStore.token}`)
    currentConnection.value.onmessage = (event) => {
        console.log(event);
    }
    currentConnection.value.onopen = (event) => {
        console.log(event);
        console.log("Connected");
    }
    currentConnection.value.onerror = (event) => {
        console.log(event);
    }
}

const form = ref({
    name: ""
})
</script>

<template>
    <form class="w-[300px] border rounded-md flex flex-col p-4 gap-2"
        @submit.prevent="() => userStore.createChatroom(form)">
        <h1 class="text-lg font-bold">Create Chatroom</h1>
        <fieldset class="flex flex-col gap-2">
            <label for="name">Name</label>
            <input class="p-2 border rounded-md" 
                type="text" id="name" v-model="form.name" minlength="1" required>
        </fieldset>
        <button class="w-[100px] self-end bg-slate-300 shadow-md rounded-md px-2"
            type="submit">Create</button>
    </form>
    <div v-if="!loading" class="flex flex-col">
        Chatrooms:
        <ul>
            <div class="border w-[150px] p-2 rounded-md flex flex-col justify-center items-center" 
                v-for="chatroom in userStore.chatrooms">
                <p>{{ chatroom.name }}</p>
                <button class="bg-slate-300 px-2 rounded-md shadow-md"
                @click="() => connect(chatroom.id)">Connect</button>
            </div>
        </ul>
    </div>

</template>
