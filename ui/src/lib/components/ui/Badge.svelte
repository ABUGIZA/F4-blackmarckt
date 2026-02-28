<script lang="ts">
	import type { Snippet } from 'svelte';

	type BadgeTone = 'accent' | 'neutral' | 'warning' | 'danger';

	interface Props {
		tone?: BadgeTone;
		children?: Snippet;
	}

	let { tone = 'neutral', children }: Props = $props();
</script>

<span class={`bm-badge bm-badge--${tone}`}>
	{@render children?.()}
</span>

<style>
	.bm-badge {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.15rem 0.45rem;
		border-radius: 2px;
		border: 1px solid transparent;
		font-size: 0.7rem;
		font-weight: 600;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		line-height: 1.1;
	}

	.bm-badge--accent {
		background: var(--accent-soft);
		border-color: var(--accent-border);
		color: var(--accent-primary);
	}

	.bm-badge--neutral {
		background: rgb(255 255 255 / 4%);
		border-color: rgb(255 255 255 / 14%);
		color: var(--text-muted);
	}

	.bm-badge--warning {
		background: rgb(255 181 66 / 20%);
		border-color: rgb(255 181 66 / 45%);
		color: #f9bf66;
	}

	.bm-badge--danger {
		background: rgb(244 77 77 / 20%);
		border-color: rgb(244 77 77 / 45%);
		color: #ff7f7f;
	}
</style>
