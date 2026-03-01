<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		eyebrow?: string;
		title: string;
		description?: string;
		actions?: Snippet;
	}

	let { eyebrow, title, description, actions }: Props = $props();
</script>

<header class="bm-section-header">
	<div class="bm-section-header__copy">
		{#if eyebrow}
			<p class="eyebrow">{eyebrow}</p>
		{/if}
		<h1>{title}</h1>
		{#if description}
			<p class="description">{description}</p>
		{/if}
	</div>

	{#if actions}
		<div class="bm-section-header__actions">
			{@render actions()}
		</div>
	{/if}
</header>

<style>
	.bm-section-header {
		display: flex;
		flex-wrap: wrap;
		align-items: end;
		justify-content: space-between;
		gap: 1rem;
	}

	.bm-section-header__copy {
		display: grid;
		gap: 0.28rem;
	}

	.eyebrow {
		width: fit-content;
		margin: 0;
		padding: 0.22rem 0.58rem;
		border-radius: 999px;
		font-size: 0.69rem;
		font-weight: 700;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--accent-primary);
		background: var(--accent-soft);
		border: 1px solid var(--accent-border);
	}

	h1 {
		margin: 0;
		font-size: clamp(1.4rem, 3vw, 2.15rem);
		letter-spacing: -0.02em;
		line-height: 1.03;
	}

	.description {
		margin: 0;
		color: var(--text-muted);
		max-width: 58ch;
	}

	.bm-section-header__actions {
		display: inline-flex;
		flex-wrap: wrap;
		gap: 0.55rem;
	}
</style>
