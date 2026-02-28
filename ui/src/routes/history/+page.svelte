<script lang="ts">
	import { HistoryList, HistoryPagination } from '$lib/components/history';
	import type { HistoryListItem } from '$lib/components/history';
	import { LinkButton, SectionHeader } from '$lib/components/ui';
	import { getCategoryName, getHistoryPage, historyEntries, serverProducts } from '$lib/stores';

	const pageSize = 6;
	let currentPage = $state(1);

	const pageData = $derived.by(() => {
		$historyEntries;
		return getHistoryPage(currentPage, pageSize);
	});

	const totalEntries = $derived(pageData.total);
	const totalPages = $derived(pageData.totalPages);

	const pageItems = $derived.by(
		(): HistoryListItem[] => {
			return pageData.items.map((entry) => {
				const product = $serverProducts.find((p) => p.id === entry.productId);
				return {
					id: entry.id,
					productId: entry.productId,
					productName: entry.productName,
					productImage: product?.image ?? '',
					categoryId: entry.categoryId,
					categoryName: getCategoryName(entry.categoryId),
					rarity: entry.rarity ?? product?.rarity ?? 'common',
					quantity: entry.quantity ?? 1,
					pricePaid: entry.pricePaid,
					status: entry.status,
					purchasedAt: entry.purchasedAt
				};
			});
		}
	);

	const handlePageChange = (page: number) => {
		currentPage = Math.min(Math.max(page, 1), totalPages);
	};

	$effect(() => {
		if (currentPage > totalPages) currentPage = totalPages;
	});
</script>

<section class="history-screen">
	<SectionHeader
		eyebrow="Market Archive"
		title="Purchase History"
		description="Track all simulated transactions with status, category, timestamp, and paid amount."
	>
		{#snippet actions()}
			<LinkButton href="/market" variant="soft">Back to Market</LinkButton>
		{/snippet}
	</SectionHeader>

	<HistoryList items={pageItems} />
	{#if totalEntries > 0}
		<HistoryPagination
			{currentPage}
			{totalPages}
			totalItems={totalEntries}
			{pageSize}
			onPageChange={handlePageChange}
		/>
	{/if}
</section>

<style>
	.history-screen {
		min-height: inherit;
		display: grid;
		align-content: start;
		gap: 0.95rem;
		padding: clamp(0.85rem, 2vw, 1.5rem);
		overflow-y: auto;
		max-height: 100dvh;
	}
</style>
