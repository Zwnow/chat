import { defineStore } from "pinia";
import { ref } from "vue";

export const useUserStore = defineStore('user', () => {
    const token = ref<string>();
    const isAuthenticated = ref<boolean>(false);
    const userID = ref<string>();
    const chatrooms = ref([]);

    const authenticate = async () => {
        const r = await fetch("http://localhost/validate-token", {
            headers: {
                "Authorization": `Bearer ${token.value}`
            }
        });
        if (r.status === 200) {
            isAuthenticated.value = true;
        }
    }

    const getChatrooms = async () => {
        const r = await fetch("http://localhost/api/chatroom", {
            headers: {
                "Authorization": `Bearer ${token.value}`
            }
        });
        const data = await r.json();
        chatrooms.value = data.chatrooms;
    }

    const createChatroom = async () => {
        const r = await fetch("http://localhost/api/chatroom", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${token.value}`
            }
        });
        if (r.status === 200) {
            await getChatrooms();
        }
    }

    return {
        token,
        userID,
        chatrooms,
        isAuthenticated,
        authenticate,
        getChatrooms,
        createChatroom,
    }
});
