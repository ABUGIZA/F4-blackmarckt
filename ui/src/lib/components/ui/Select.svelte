<script lang="ts">
	import { fade } from "svelte/transition";

	export interface SelectOption {
		label: string;
		value: string;
		disabled?: boolean;
	}

	interface Props {
		label?: string;
		hint?: string;
		error?: string;
		options: SelectOption[];
		value?: string;
		id?: string;
		class?: string;
	}

	let {
		label,
		hint,
		error,
		options,
		value = $bindable(""),
		id,
		class: className = "",
	}: Props = $props();

	let isOpen = $state(false);
	let activeIndex = $state(-1);
	let container: HTMLDivElement;

	const listboxId = $derived(id ? `${id}-listbox` : undefined);
	const feedbackId = $derived(id ? `${id}-feedback` : undefined);

	const selectedLabel = $derived(
		options.find((o) => o.value === value)?.label || "Select option",
	);

	function toggle() {
		isOpen = !isOpen;
		if (isOpen) {
			activeIndex = options.findIndex((o) => o.value === value);
		}
	}

	function open() {
		if (!isOpen) {
			isOpen = true;
			activeIndex = options.findIndex((o) => o.value === value);
		}
	}

	function close() {
		isOpen = false;
		activeIndex = -1;
	}

	function select(option: SelectOption) {
		if (option.disabled) return;
		value = option.value;
		close();
	}

	function handleKeydown(event: KeyboardEvent) {
		switch (event.key) {
			case "ArrowDown":
				event.preventDefault();
				if (!isOpen) {
					open();
				} else {
					activeIndex = Math.min(activeIndex + 1, options.length - 1);
				}
				break;
			case "ArrowUp":
				event.preventDefault();
				if (!isOpen) {
					open();
				} else {
					activeIndex = Math.max(activeIndex - 1, 0);
				}
				break;
			case "Enter":
			case " ":
				event.preventDefault();
				if (isOpen && activeIndex >= 0 && !options[activeIndex]?.disabled) {
					select(options[activeIndex]);
				} else {
					open();
				}
				break;
			case "Escape":
				event.preventDefault();
				close();
				break;
			case "Home":
				if (isOpen) {
					event.preventDefault();
					activeIndex = 0;
				}
				break;
			case "End":
				if (isOpen) {
					event.preventDefault();
					activeIndex = options.length - 1;
				}
				break;
		}
	}

	// Close on click outside
	$effect(() => {
		const handleClick = (e: MouseEvent) => {
			if (container && !container.contains(e.target as Node)) {
				close();
			}
		};

		if (isOpen) {
			window.addEventListener("click", handleClick);
		}

		return () => window.removeEventListener("click", handleClick);
	});
</script>

<div class={`bm-select-container ${className}`} bind:this={container}>
	{#if label}
		<!-- svelte-ignore a11y_label_has_associated_control -->
		<label class="bm-label" id={id ? `${id}-label` : undefined}>{label}</label>
	{/if}

	<div class="bm-select-rel">
		<button
			{id}
			type="button"
			class="bm-select-trigger"
			class:is-open={isOpen}
			class:has-error={Boolean(error)}
			role="combobox"
			aria-expanded={isOpen}
			aria-haspopup="listbox"
			aria-controls={listboxId}
			aria-labelledby={id ? `${id}-label` : undefined}
			aria-describedby={(error || hint) ? feedbackId : undefined}
			aria-activedescendant={isOpen && activeIndex >= 0 && id ? `${id}-opt-${activeIndex}` : undefined}
			onclick={toggle}
			onkeydown={handleKeydown}
		>
			<span class="trigger-text">{selectedLabel}</span>
			<div class="trigger-icon">
				<svg
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="3"
				>
					<path d="m6 9 6 6 6-6" />
				</svg>
			</div>
		</button>

		{#if isOpen}
			<div
				class="bm-select-dropdown"
				id={listboxId}
				role="listbox"
				aria-labelledby={id ? `${id}-label` : undefined}
				transition:fade={{ duration: 100 }}
			>
				<div class="dropdown-inner">
					{#each options as option, i (option.value)}
						<button
							type="button"
							id={id ? `${id}-opt-${i}` : undefined}
							class="dropdown-item"
							class:is-active={value === option.value}
							class:is-focused={activeIndex === i}
							class:is-disabled={option.disabled}
							role="option"
							aria-selected={value === option.value}
							aria-disabled={option.disabled}
							onclick={() => select(option)}
							onmouseenter={() => (activeIndex = i)}
						>
							{option.label}
							{#if value === option.value}
								<div class="active-dot"></div>
							{/if}
						</button>
					{/each}
				</div>
			</div>
		{/if}
	</div>

	{#if error}
		<p id={feedbackId} class="feedback feedback--error">{error}</p>
	{:else if hint}
		<p id={feedbackId} class="feedback">{hint}</p>
	{/if}
</div>

<style>
	.bm-select-container {
		display: grid;
		gap: 0.4rem;
	}

	.bm-label {
		font-size: 0.72rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	.bm-select-rel {
		position: relative;
	}

	.bm-select-trigger {
		width: 100%;
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0.65rem 1rem;
		background: rgba(255, 255, 255, 0.02);
		border: 1px solid var(--line-soft);
		border-radius: 2px;
		color: var(--text-main);
		font-size: 0.8rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		cursor: pointer;
		transition: all 0.2s ease;
		text-align: left;
	}

	.bm-select-trigger:hover {
		background: rgba(255, 255, 255, 0.04);
		border-color: var(--text-muted);
	}

	.bm-select-trigger.is-open {
		border-color: var(--accent-primary);
		background: rgba(24, 213, 143, 0.05);
	}

	.trigger-icon {
		width: 14px;
		height: 14px;
		color: var(--text-dim);
		transition: transform 0.2s ease;
	}

	.is-open .trigger-icon {
		transform: rotate(180deg);
		color: var(--accent-primary);
	}

	.bm-select-dropdown {
		position: absolute;
		top: calc(100% + 4px);
		left: 0;
		right: 0;
		background: var(--bg-panel);
		border: 1px solid var(--accent-border);
		border-radius: 4px;
		z-index: 100;
		box-shadow: 0 10px 40px rgba(0, 0, 0, 0.6);
	}

	.dropdown-inner {
		padding: 0.3rem;
		display: grid;
		gap: 0.15rem;
	}

	.dropdown-item {
		width: 100%;
		padding: 0.6rem 0.85rem;
		background: transparent;
		border: none;
		border-radius: 2px;
		color: var(--text-muted);
		font-size: 0.75rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		text-align: left;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: space-between;
		transition: all 0.15s ease;
	}

	.dropdown-item:hover:not(.is-disabled),
	.dropdown-item.is-focused:not(.is-disabled) {
		background: rgba(255, 255, 255, 0.04);
		color: var(--text-main);
		padding-left: 1rem;
	}

	.dropdown-item.is-active {
		background: var(--accent-soft);
		color: var(--accent-primary);
	}

	.active-dot {
		width: 4px;
		height: 4px;
		border-radius: 50%;
		background: var(--accent-primary);
	}

	.bm-select-trigger.has-error {
		border-color: rgb(244 77 77 / 45%);
	}

	.is-disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}

	.feedback {
		margin: 0;
		font-size: 0.7rem;
		color: var(--text-dim);
	}

	.feedback--error {
		color: #ff4d4d;
	}
</style>
