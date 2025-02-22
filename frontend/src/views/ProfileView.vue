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

const currentConnection = ref<EventSource|null>(null);
const connect = async (chatroom: string) => {
    currentConnection.value = new EventSource(`http://localhost/stream/${chatroom}?token=${userStore.token}`)
    currentConnection.value.onopen = function (event) {
        userStore.activeChat = chatroom;
        console.log(event);
    }

    currentConnection.value.onmessage = function (event) {
        const data = JSON.parse(event.data);
        if (data.content) {
            messages.value.push({content: data.content, name: data.username, time: data.timestamp})
        }
        console.log(data);
    }

    currentConnection.value.onerror = function (event) {
        console.log(event);
    }
}

const handleMessage = async () => {
    const r = await fetch(`http://localhost/api/messages/${userStore.activeChat}`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${userStore.token}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            content: message.value,
        }),
    })
    console.log(r);
}
const message = ref("");

const form = ref({
    name: ""
});

const chatInviteForm = ref({
    to_user_name: "",
    chatroom: ""
});

const messages = ref<any>([]);
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
    <div v-if="!loading" class="flex gap-12">
        <div class="flex flex-col">
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

        <div v-if="userStore.activeChat" class="flex flex-col">
            <form class="w-[300px] border rounded-md flex flex-col p-4 gap-2"
                @submit.prevent="() => userStore.sendChatInvitation(chatInviteForm)">
                <h1 class="text-lg font-bold">Invite to chat</h1>
                <fieldset class="flex flex-col gap-2">
                    <label for="name">Username</label>
                    <input class="p-2 border rounded-md" 
                        type="text" id="name" v-model="chatInviteForm.to_user_name" minlength="1" required>
                </fieldset>
                <button class="w-[100px] self-end bg-slate-300 shadow-md rounded-md px-2"
                    type="submit">Send</button>
            </form>
            <div class="flex flex-col gap-2 h-[400px] max-h-[400px]">
                <p v-for="message in messages">{{message.user_id}}: {{ message.content }}</p>

            </div>
            <form class="flex flex-col gap-2"
                @submit.prevent="() => handleMessage()">
                <input class="border rounded-md p-2" 
                    type="text" v-model="message" minlength="1" required>
                <button type="submit">Send Message</button>
            </form>

        </div>
    </div>
</template>
