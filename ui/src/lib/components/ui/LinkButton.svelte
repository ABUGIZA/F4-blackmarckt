<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAnchorAttributes } from 'svelte/elements';

	type ButtonVariant = 'primary' | 'soft' | 'ghost';
	type ButtonSize = 'sm' | 'md' | 'lg';

	interface Props extends Omit<HTMLAnchorAttributes, 'children'> {
		href: string;
		variant?: ButtonVariant;
		size?: ButtonSize;
		block?: boolean;
		children?: Snippet;
	}

	let {
		href,
		variant = 'primary',
		size = 'md',
		block = false,
		class: className = '',
		children,
		...rest
	}: Props = $props();

	const classes = $derived(
		['bm-link-btn', `bm-link-btn--${variant}`, `bm-link-btn--${size}`, block ? 'bm-link-btn--block' : '', className]
			.filter(Boolean)
			.join(' ')
	);
</script>

<a {href} class={classes} {...rest}>
	{@render children?.()}
</a>

<style>
	.bm-link-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.45rem;
		border-radius: 0.75rem;
		border: 1px solid transparent;
		font-weight: 700;
		letter-spacing: 0.01em;
		text-decoration: none;
		transition:
			transform 120ms ease,
			border-color 120ms ease,
			background-color 120ms ease,
			color 120ms ease,
			box-shadow 120ms ease;
	}

	.bm-link-btn:hover {
		transform: translateY(-1px);
	}

	.bm-link-btn--sm {
		padding: 0.45rem 0.75rem;
		font-size: 0.82rem;
	}

	.bm-link-btn--md {
		padding: 0.58rem 0.95rem;
		font-size: 0.9rem;
	}

	.bm-link-btn--lg {
		padding: 0.7rem 1.15rem;
		font-size: 0.98rem;
	}

	.bm-link-btn--block {
		width: 100%;
	}

	.bm-link-btn--primary {
		background: linear-gradient(125deg, var(--accent-primary), var(--accent-hover));
		color: #07120d;
		border-color: var(--accent-border);
		box-shadow: 0 10px 28px rgb(0 0 0 / 28%);
	}

	.bm-link-btn--soft {
		background: var(--accent-soft);
		color: var(--accent-primary);
		border-color: var(--accent-border);
	}

	.bm-link-btn--ghost {
		background: rgb(255 255 255 / 3%);
		color: var(--text-main);
		border-color: rgb(255 255 255 / 12%);
	}
</style>
