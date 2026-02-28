<script lang="ts">
    import { HistoryList, HistoryPagination } from "./index";
    import type { HistoryListItem } from "./index";
    import { SectionHeader } from "$lib/components/ui";
    import {
        getCategoryName,
        getHistoryPage,
        historyEntries,
        serverProducts,
    } from "$lib/stores";

    interface Props {
        onBack?: () => void;
    }

    let { onBack }: Props = $props();

    const pageSize = 6;
    let currentPage = $state(1);

    const pageData = $derived.by(() => {
        $historyEntries;
        return getHistoryPage(currentPage, pageSize);
    });

    const totalEntries = $derived(pageData.total);
    const totalPages = $derived(pageData.totalPages);

    const pageItems = $derived.by((): HistoryListItem[] => {
        return pageData.items.map((entry) => {
            const product = $serverProducts.find(
                (p) => p.id === entry.productId,
            );
            return {
                id: entry.id,
                productId: entry.productId,
                productName: entry.productName,
                productImage: product?.image || "",
                categoryId: entry.categoryId,
                categoryName: getCategoryName(entry.categoryId),
                rarity: entry.rarity ?? product?.rarity ?? "common",
                quantity: entry.quantity ?? 1,
                pricePaid: entry.pricePaid,
                status: entry.status,
                purchasedAt: entry.purchasedAt,
            };
        });
    });

    const stats = $derived.by(() => {
        const entries = $historyEntries;
        const successful = entries.filter((e) => e.status === "success");
        const spent = successful.reduce((acc, curr) => acc + curr.pricePaid, 0);
        return {
            total: entries.length,
            successRate: entries.length
                ? Math.round((successful.length / entries.length) * 100)
                : 0,
            spent,
        };
    });

    const handlePageChange = (page: number) => {
        currentPage = Math.min(Math.max(page, 1), totalPages);
    };

    $effect(() => {
        if (currentPage > totalPages) currentPage = totalPages;
    });
</script>

<div class="history-view">
    <SectionHeader
        eyebrow="Market Archive"
        title="Purchase History"
        description="Track all transactions and financial movements within the terminal."
    >
        {#snippet actions()}
            {#if onBack}
                <button type="button" class="back-btn" onclick={onBack}>
                    Back to Market
                </button>
            {/if}
        {/snippet}
    </SectionHeader>

    <div class="summary-grid">
        <div class="summary-card">
            <span class="summary-label">TOTAL OPERATIONS</span>
            <span class="summary-value">{stats.total}</span>
        </div>
        <div class="summary-card">
            <span class="summary-label">SUCCESS RATE</span>
            <span class="summary-value">{stats.successRate}%</span>
        </div>
        <div class="summary-card aura-accent">
            <span class="summary-label">TOTAL CAPITAL SPENT</span>
            <span class="summary-value">${stats.spent.toLocaleString()}</span>
        </div>
    </div>

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
</div>

<style>
    .history-view {
        display: grid;
        align-content: start;
        gap: 0.95rem;
        animation: view-in 0.3s ease;
    }

    .summary-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 0.6rem;
        margin-bottom: 0.25rem;
    }

    .summary-card {
        background: rgba(255, 255, 255, 0.02);
        border: 1px solid var(--line-soft);
        padding: 0.75rem 1rem;
        border-radius: 4px;
        display: flex;
        flex-direction: column;
        gap: 0.15rem;
    }

    .summary-card.aura-accent {
        border-color: var(--accent-border);
        background: var(--accent-soft);
    }

    .summary-label {
        font-size: 0.55rem;
        font-weight: 700;
        color: var(--text-dim);
        letter-spacing: 0.12em;
    }

    .summary-value {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--text-main);
    }

    .aura-accent .summary-value {
        color: var(--accent-primary);
    }

    .back-btn {
        background: var(--accent-soft);
        border: 1px solid var(--accent-primary);
        color: var(--accent-primary);
        padding: 0.5rem 1.2rem;
        border-radius: 4px;
        font-size: 0.7rem;
        font-weight: 700;
        text-transform: uppercase;
        cursor: pointer;
        transition: all 0.2s ease;
        letter-spacing: 0.05em;
    }

    .back-btn:hover {
        background: var(--accent-primary);
        color: #000;
    }

    @keyframes view-in {
        from {
            opacity: 0;
            transform: translateY(10px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
</style>
