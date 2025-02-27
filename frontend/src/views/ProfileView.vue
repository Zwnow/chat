<script setup lang="ts">
import { useUserStore } from "@/stores/userStore";
import { watch, nextTick, onMounted, ref } from "vue";

const userStore = useUserStore();
const loading = ref(true);
const hasError = ref(false);
const connectionStatus = ref("Not connected");
onMounted(async () => {
    loading.value = true;
    try {
        await userStore.getChatrooms();
        let conn = sessionStorage.getItem("chatroom")
        if (conn !== null) {
            await connect(conn);
        }
    } catch(e) {
        hasError.value = true;
    }
    loading.value = false;

})

const currentConnection = ref<EventSource|null>(null);
const connect = async (chatroom: string) => {
    currentConnection.value = new EventSource(`http://localhost:4000/chatroom/${chatroom}/${userStore.token}`)
    sessionStorage.setItem("chatroom", chatroom)

    currentConnection.value.onopen = function (event) {
        connectionStatus.value = "Connected"
        userStore.activeChat = chatroom;
    }

    currentConnection.value.onmessage = function (event) {
        const data = JSON.parse(event.data);
        if (data.user) {
            messages.value.push({message: data.message, user: data.user, time: new Date()})
        }
    }

    currentConnection.value.onerror = function (event) {
        if (currentConnection.value!.readyState === EventSource.CLOSED) {
            connectionStatus.value = "Disconnected"
            currentConnection.value = null;
        }
    }
}

const handleMessage = async () => {
    const r = await fetch(`http://localhost:4000/message/${userStore.activeChat}`, {
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
watch(messages.value, async (_new, _old) => {
    await nextTick();
    const div = document.getElementById("chat_container");
    if (div !== null) {
        div.scrollTop = div.scrollHeight;
    }
});
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
            <div>{{ connectionStatus }}</div>
            <div 
                id="chat_container"
                class="flex flex-col gap-2 h-[400px] max-h-[400px] overflow-y-scroll">
                <p v-for="message in messages">{{message.user}}: {{ message.message }}</p>
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
