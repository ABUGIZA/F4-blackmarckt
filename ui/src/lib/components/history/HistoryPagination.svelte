<script lang="ts">
	import { Button } from "$lib/components/ui";

	interface Props {
		currentPage: number;
		totalPages: number;
		totalItems: number;
		pageSize: number;
		onPageChange: (page: number) => void;
	}

	let { currentPage, totalPages, totalItems, pageSize, onPageChange }: Props =
		$props();

	const canGoPrev = $derived(currentPage > 1);
	const canGoNext = $derived(currentPage < totalPages);

	const pageWindow = $derived.by(() => {
		if (totalPages <= 1) return [1];

		const maxVisible = 5;
		let start = Math.max(1, currentPage - 2);
		let end = Math.min(totalPages, start + maxVisible - 1);

		if (end - start + 1 < maxVisible) {
			start = Math.max(1, end - maxVisible + 1);
		}

		return Array.from(
			{ length: end - start + 1 },
			(_, index) => start + index,
		);
	});

	const startItem = $derived(
		totalItems === 0 ? 0 : (currentPage - 1) * pageSize + 1,
	);
	const endItem = $derived(
		totalItems === 0 ? 0 : Math.min(totalItems, currentPage * pageSize),
	);
</script>

<div class="history-pagination">
	<p class="summary">
		Showing {startItem}-{endItem} of {totalItems} purchases
	</p>

	<div class="controls">
		<Button
			size="sm"
			variant="ghost"
			disabled={!canGoPrev}
			onclick={() => onPageChange(currentPage - 1)}
		>
			PREV
		</Button>

		<div class="page-numbers">
			{#each pageWindow as page (page)}
				<Button
					size="sm"
					variant={page === currentPage ? "primary" : "ghost"}
					onclick={() => onPageChange(page)}
				>
					{page}
				</Button>
			{/each}
		</div>

		<Button
			size="sm"
			variant="ghost"
			disabled={!canGoNext}
			onclick={() => onPageChange(currentPage + 1)}
		>
			NEXT
		</Button>
	</div>
</div>

<style>
	.history-pagination {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding: 0.75rem 1rem;
		border: 1px solid var(--line-soft);
		border-radius: 4px;
		background: rgba(255, 255, 255, 0.01);
	}

	.summary {
		margin: 0;
		color: var(--text-dim);
		font-size: 0.7rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	.controls {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.page-numbers {
		display: flex;
		gap: 0.25rem;
	}
</style>
