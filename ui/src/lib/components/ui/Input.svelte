<script lang="ts">
	import type { HTMLInputAttributes } from "svelte/elements";

	interface Props extends Omit<HTMLInputAttributes, "children" | "value"> {
		label?: string;
		hint?: string;
		error?: string;
		value?: string;
	}

	let {
		label,
		hint,
		error,
		value = $bindable(""),
		id,
		type = "text",
		class: className = "",
		...rest
	}: Props = $props();

	const feedbackId = $derived(id ? `${id}-feedback` : undefined);
</script>

<div class={`bm-field ${className}`}>
	{#if label}
		<label for={id}>{label}</label>
	{/if}

	<input
		{id}
		{type}
		bind:value
		class:error={Boolean(error)}
		aria-invalid={error ? "true" : undefined}
		aria-describedby={(error || hint) ? feedbackId : undefined}
		{...rest}
	/>

	{#if error}
		<p id={feedbackId} class="feedback feedback--error">{error}</p>
	{:else if hint}
		<p id={feedbackId} class="feedback">{hint}</p>
	{/if}
</div>

<style>
	.bm-field {
		display: grid;
		gap: 0.38rem;
	}

	label {
		font-size: 0.79rem;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	input {
		width: 100%;
		padding: 0.75rem 1rem;
		border-radius: 2px;
		border: 1px solid var(--line-soft);
		background: rgba(255, 255, 255, 0.02);
		color: var(--text-main);
		font-size: 0.9rem;
		transition: border-color 0.2s ease;
	}

	input:hover:not(:focus) {
		border-color: var(--text-muted);
		background: rgba(255, 255, 255, 0.04);
	}

	input:focus {
		outline: none;
		border-color: var(--accent-primary);
		background: rgba(13, 18, 20, 0.8);
	}

	input.error {
		border-color: rgb(244 77 77 / 45%);
	}

	.feedback {
		margin: 0;
		color: var(--text-dim);
		font-size: 0.75rem;
	}

	.feedback--error {
		color: #ff8484;
	}
</style>
