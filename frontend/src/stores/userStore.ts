import { defineStore } from "pinia";
import { ref } from "vue";

type Chatroom = {
    id: string
    user_id: string
    name: string
    timestamp: string
}

type Chatinvite = {
    id: string
    chatroom: string
    from_user_id: number
    from_user_name: string
    to_user_id: number
    to_user_name: string
    name: string
    timestamp: string
}

type ChatroomForm = {
    name: string
}

type ChatInviteForm = {
    to_user_name: string
    chatroom: string
}

export const useUserStore = defineStore('user', () => {
    const token = ref<string>();
    const isAuthenticated = ref<boolean>(false);
    const userID = ref<string>();
    const activeChat = ref();
    const chatrooms = ref<Chatroom[]>([]);
    const chatinvites = ref<Chatinvite[]>([]);

    const authenticate = async () => {
        const r = await fetch("http://localhost:4000/validate-token", {
            headers: {
                "Authorization": `Bearer ${token.value}`
            }
        });
        if (r.status === 200) {
            isAuthenticated.value = true;
        }
    }

    const getChatrooms = async () => {
        const r = await fetch("http://localhost:4000/chatroom", {
            headers: {
                "Authorization": `Bearer ${token.value}`
            }
        });
        const data = await r.json();

        chatrooms.value = data;
    }

    const createChatroom = async (form: ChatroomForm) => {
        const r = await fetch("http://localhost:4000/chatroom", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${token.value}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify(form)
        });
        if (r.status === 200) {
            await getChatrooms();
        }
    }

    const sendChatInvitation = async (form: ChatInviteForm) => {
        const r = await fetch("http://localhost:4000/chatinvite", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${token.value}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                chatroom: activeChat.value,
                to_user: form.to_user_name,
            }),
        });
    }

    const getChatInvites = async () => {
        const r = await fetch("http://localhost:4000/chatinvite", {
            method: "GET",
            headers: {
                "Authorization": `Bearer ${token.value}`,
                "Content-Type": "application/json",
            },
        });

        if (r.status === 200) {
            const data = await r.json();
            console.log(data)
            chatinvites.value = data.invites;
        }
    }

    const acceptInvite = async (invite: Chatinvite) => {
        const r = await fetch("http://localhost:4000/invitation/accept", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${token.value}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                invite_id: invite.id,
                chatroom: invite.chatroom,
            }),
        });
    }

    const declineInvite = async (invite: Chatinvite) => {
        const r = await fetch("http://localhost:4000/invitation/decline", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${token.value}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                invite_id: invite.id,
                chatroom: invite.chatroom,
            }),
        });
    }

    return {
        token,
        userID,
        chatrooms,
        chatinvites,
        activeChat,
        isAuthenticated,
        authenticate,
        getChatrooms,
        createChatroom,
        sendChatInvitation,
        getChatInvites,
        acceptInvite,
        declineInvite,
    }
});
