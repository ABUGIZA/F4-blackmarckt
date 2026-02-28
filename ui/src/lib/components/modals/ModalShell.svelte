<script lang="ts">
	import type { Snippet } from "svelte";

	interface Props {
		title: string;
		subtitle?: string;
		label?: string;
		labelColor?: string;
		maxWidth?: string;
		children?: Snippet;
		footer?: Snippet;
	}

	let {
		title,
		subtitle,
		label = "Product Details",
		labelColor = "var(--accent-primary)",
		maxWidth = "540px",
		children,
		footer,
	}: Props = $props();
</script>

<section class="bm-modal-shell" style={`--bm-modal-max-width: ${maxWidth};`}>
	<header class="bm-modal-shell__header">
		{#if label}
			<p class="bm-modal-shell__label" style={`color: ${labelColor}`}>
				{label}
			</p>
		{/if}
		<h2>{title}</h2>
		{#if subtitle}
			<p class="bm-modal-shell__subtitle">{subtitle}</p>
		{/if}
	</header>

	<div class="bm-modal-shell__content">
		{@render children?.()}
	</div>

	{#if footer}
		<footer class="bm-modal-shell__footer">
			{@render footer()}
		</footer>
	{/if}
</section>

<style>
	.bm-modal-shell {
		width: 100%;
		max-width: var(--bm-modal-max-width);
		display: grid;
		gap: 0.9rem;
		padding: 1.25rem;
		border-radius: 4px;
		border: 1px solid var(--line-soft);
		background: var(--bg-surface);
		position: relative;
	}

	.bm-modal-shell::before {
		content: "";
		position: absolute;
		inset: 0;
		background: linear-gradient(
			135deg,
			rgba(255, 255, 255, 0.03),
			transparent 40%
		);
		pointer-events: none;
	}

	.bm-modal-shell__header {
		display: grid;
		gap: 0.22rem;
	}

	.bm-modal-shell__label {
		margin: 0;
		font-size: 0.7rem;
		font-weight: 500;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		color: var(--accent-primary);
	}

	h2 {
		margin: 0;
		font-size: 1.25rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		color: var(--text-main);
	}

	.bm-modal-shell__subtitle {
		margin: 0;
		color: var(--text-muted);
		font-size: 0.9rem;
	}

	.bm-modal-shell__content {
		display: grid;
		gap: 0.65rem;
	}

	.bm-modal-shell__footer {
		display: flex;
		flex-wrap: wrap;
		justify-content: flex-end;
		gap: 0.55rem;
		padding-top: 0.72rem;
		border-top: 1px solid rgb(255 255 255 / 10%);
	}
</style>
