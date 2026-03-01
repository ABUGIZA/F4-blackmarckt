<script lang="ts">
	import type { Snippet } from "svelte";
	import type { HTMLButtonAttributes } from "svelte/elements";

	type ButtonVariant = "primary" | "soft" | "ghost";
	type ButtonSize = "sm" | "md" | "lg";

	interface Props extends Omit<HTMLButtonAttributes, "children"> {
		variant?: ButtonVariant;
		size?: ButtonSize;
		block?: boolean;
		children?: Snippet;
	}

	let {
		variant = "primary",
		size = "md",
		block = false,
		type = "button",
		class: className = "",
		children,
		...rest
	}: Props = $props();

	const classes = $derived(
		[
			"bm-btn",
			`bm-btn--${variant}`,
			`bm-btn--${size}`,
			block ? "bm-btn--block" : "",
			className,
		]
			.filter(Boolean)
			.join(" "),
	);
</script>

<button {type} class={classes} {...rest}>
	{@render children?.()}
</button>

<style>
	.bm-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.45rem;
		border-radius: 4px; /* Sharper corners for tactical feel */
		border: 1px solid transparent;
		font-weight: 600;
		letter-spacing: 0.04em;
		text-transform: uppercase;
		cursor: pointer;
		position: relative;
		overflow: hidden;
		transition:
			transform 120ms ease,
			border-color 120ms ease,
			background-color 120ms ease,
			color 120ms ease,
			box-shadow 120ms ease;
	}

	.bm-btn:hover:enabled {
		filter: brightness(1.1);
		border-color: var(--accent-primary);
	}

	.bm-btn::after {
		content: "";
		position: absolute;
		inset: 0;
		background: linear-gradient(
			90deg,
			transparent,
			rgba(255, 255, 255, 0.1),
			transparent
		);
		transform: translateX(-100%);
		transition: transform 0.6s ease;
	}

	.bm-btn:hover:enabled::after {
		transform: translateX(100%);
	}

	.bm-btn:disabled {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.bm-btn--sm {
		padding: 0.45rem 0.75rem;
		font-size: 0.82rem;
	}

	.bm-btn--md {
		padding: 0.58rem 0.95rem;
		font-size: 0.9rem;
	}

	.bm-btn--lg {
		padding: 0.7rem 1.15rem;
		font-size: 0.98rem;
	}

	.bm-btn--block {
		width: 100%;
	}

	.bm-btn--primary {
		background: var(--accent-primary);
		color: #020404;
		border-color: var(--accent-primary);
	}

	.bm-btn--soft {
		background: transparent;
		color: var(--accent-primary);
		border-color: var(--accent-border);
	}

	.bm-btn--soft:hover:enabled {
		background: var(--accent-soft);
	}

	.bm-btn--ghost {
		background: transparent;
		color: var(--text-muted);
		border-color: var(--line-soft);
	}

	.bm-btn--ghost:hover:enabled {
		color: var(--text-main);
		border-color: var(--text-muted);
		background: rgba(255, 255, 255, 0.03);
	}
</style>
