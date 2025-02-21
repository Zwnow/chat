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
</script>

<template>
    <button @click="() => userStore.createChatroom()">Create chatroom</button>
    <div v-if="!loading" class="flex flex-col">
        Chatrooms:
        <ul>
            <div class="border w-[150px] p-2 rounded-md flex flex-col justify-center items-center" 
                v-for="chatroom, index in userStore.chatrooms">
                <p>Chatroom {{ index + 1 }}</p>
                <button class="bg-slate-300 px-2 rounded-md shadow-md"
                @click="() => connect(chatroom.id)">Connect</button>
            </div>
        </ul>
    </div>

</template>
