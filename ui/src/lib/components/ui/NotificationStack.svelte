<script lang="ts">
	import type { NotificationEntry } from "$lib/stores/ui.store";

	interface Props {
		items: NotificationEntry[];
		onDismiss: (id: string) => void;
	}

	let { items, onDismiss }: Props = $props();

	const toneClass = (type: NotificationEntry["type"]) => {
		if (
			type === "purchase_success" ||
			type === "level_up" ||
			type === "cart_add"
		)
			return "is-success";
		if (type === "purchase_fail" || type === "market_closed")
			return "is-danger";
		if (type === "offer_expired") return "is-warning";
		return "";
	};
</script>

{#if items.length > 0}
	<div class="bm-notification-stack" aria-live="polite">
		{#each items as item (item.id)}
			<article class={`bm-note ${toneClass(item.type)}`}>
				<p>{item.message}</p>
				<button
					type="button"
					aria-label="Dismiss notification"
					onclick={() => onDismiss(item.id)}>x</button
				>
			</article>
		{/each}
	</div>
{/if}

<style>
	.bm-notification-stack {
		position: fixed;
		top: 1rem;
		right: 1rem;
		width: min(360px, calc(100vw - 2rem));
		display: grid;
		gap: 0.55rem;
		z-index: 80;
	}

	.bm-note {
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 1rem;
		align-items: center;
		padding: 0.8rem 1rem;
		border-radius: 2px;
		border: 1px solid var(--line-soft);
		background: rgba(13, 18, 20, 0.95);
		backdrop-filter: blur(8px);
		-webkit-backdrop-filter: blur(8px);
		position: relative;
		overflow: hidden;
	}

	.bm-note::before {
		content: "";
		position: absolute;
		left: 0;
		top: 0;
		bottom: 0;
		width: 3px;
		background: var(--text-muted);
	}

	.bm-note.is-success::before {
		background: #18d58f;
	}

	.bm-note.is-danger::before {
		background: #ff4d4d;
	}

	.bm-note.is-warning::before {
		background: #ffb542;
	}

	.bm-note.is-success {
		border-color: rgb(24 213 143 / 45%);
	}

	.bm-note.is-danger {
		border-color: rgb(255 111 111 / 48%);
	}

	.bm-note.is-warning {
		border-color: rgb(255 181 66 / 48%);
	}

	.bm-note p {
		margin: 0;
		font-size: 0.86rem;
		color: var(--text-main);
	}

	.bm-note button {
		padding: 0.1rem 0.34rem;
		border-radius: 0.4rem;
		border: 1px solid rgb(255 255 255 / 20%);
		background: rgb(255 255 255 / 3%);
		color: var(--text-muted);
		cursor: pointer;
	}
</style>
