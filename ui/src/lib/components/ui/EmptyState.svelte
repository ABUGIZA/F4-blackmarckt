<script lang="ts">
	import type { Snippet } from 'svelte';
	import LinkButton from './LinkButton.svelte';

	interface Props {
		title: string;
		description: string;
		actionLabel?: string;
		actionHref?: string;
		actions?: Snippet;
	}

	let { title, description, actionLabel, actionHref, actions }: Props = $props();
</script>

<div class="bm-empty-state">
	<h2>{title}</h2>
	<p>{description}</p>

	{#if actions}
		<div class="bm-empty-state__actions">
			{@render actions()}
		</div>
	{:else if actionLabel && actionHref}
		<div class="bm-empty-state__actions">
			<LinkButton href={actionHref} variant="soft" size="sm">{actionLabel}</LinkButton>
		</div>
	{/if}
</div>

<style>
	.bm-empty-state {
		display: grid;
		gap: 0.55rem;
		padding: 1rem;
		border-radius: 0.82rem;
		border: 1px dashed rgb(255 255 255 / 14%);
		background: rgb(0 0 0 / 20%);
		text-align: center;
		place-items: center;
	}

	h2 {
		margin: 0;
		font-size: 1rem;
	}

	p {
		margin: 0;
		color: var(--text-muted);
		max-width: 46ch;
	}

	.bm-empty-state__actions {
		margin-top: 0.3rem;
	}
</style>
