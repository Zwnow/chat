<script setup lang="ts">
import { useUserStore } from "@/stores/userStore";
import { onMounted } from "vue";

const userStore = useUserStore();
onMounted(async () => {
    await userStore.getChatInvites();
});
</script>

<template>
    <ul v-if="userStore.chatinvites">
        <div v-for="invite in userStore.chatinvites">
            <p>Invitations</p>
            <button
                @click="() => userStore.acceptInvite(invite)"
            >Accept</button>
            <button
                @click="() => userStore.declineInvite(invite)"
            >Decline</button>
        </div>
    </ul>
</template>

