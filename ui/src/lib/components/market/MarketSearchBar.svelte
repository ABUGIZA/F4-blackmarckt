<script lang="ts">
	import { Card, Input, Select } from "$lib/components/ui";
	import type { SelectOption } from "$lib/components/ui";

	interface Props {
		search: string;
		sortBy: string;
		sortOptions: SelectOption[];
	}

	let {
		search = $bindable(""),
		sortBy = $bindable(""),
		sortOptions,
	}: Props = $props();
</script>

<Card class="search-card">
	<div class="controls">
		<Input
			label="Search"
			placeholder="Search items..."
			bind:value={search}
		/>
		<Select label="Sort" bind:value={sortBy} options={sortOptions} />
	</div>
</Card>

<style>
	:global(.search-card) {
		overflow: visible !important;
	}

	/* Keep only inner-field hover; outer search card stays static */
	:global(article.bm-card.search-card:hover) {
		border-color: var(--line-soft);
		background: var(--bg-panel);
	}

	:global(article.bm-card.search-card .corner-accent) {
		display: none;
	}

	.controls {
		display: grid;
		grid-template-columns: 1fr 220px;
		gap: 0.65rem;
	}

	@media (max-width: 720px) {
		.controls {
			grid-template-columns: 1fr;
		}
	}
</style>
