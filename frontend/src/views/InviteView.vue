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
            <p>{{ invite.from_user_name }}</p>
            <button
                @click="() => userStore.answerInvite(invite, true)"
            >Accept</button>
            <button
                @click="() => userStore.answerInvite(invite, false)"
            >Decline</button>
        </div>
    </ul>
</template>

