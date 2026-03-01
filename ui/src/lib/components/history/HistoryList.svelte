<script lang="ts">
	import { EmptyState } from "$lib/components/ui";
	import { inventoryImageBaseUrl } from "$lib/stores";

	export interface HistoryListItem {
		id: string;
		productId: string;
		productName: string;
		productImage: string;
		categoryId: string;
		categoryName: string;
		rarity: "common" | "uncommon" | "rare" | "epic" | "legendary";
		quantity: number;
		pricePaid: number;
		status: "success" | "failed";
		purchasedAt: string;
	}

	interface Props {
		items: HistoryListItem[];
	}

	let { items }: Props = $props();

	const formatPrice = (value: number) => `$${value.toLocaleString("en-US")}`;
	const formatDate = (value: string) => {
		if (!value) return "—";
		const date = new Date(value);
		if (isNaN(date.getTime())) return "—";
		return new Intl.DateTimeFormat("en-US", {
			month: "short",
			day: "numeric",
			hour: "2-digit",
			minute: "2-digit",
			hour12: true,
		}).format(date);
	};

	const icons: Record<string, string> = {
		explosives: `<path d="M19 5L5 19M19 19L5 5" stroke-width="2.5"/><circle cx="12" cy="12" r="8"/>`,
		tools: `<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.77 3.77Z"/>`,
		electronics: `<rect x="2" y="2" width="20" height="20" rx="2" ry="2"/><path d="M7 2v2M12 2v2M17 2v2M7 20v2M12 20v2M17 20v2M2 7h2M2 12h2M2 17h2M20 7h2M20 12h2M20 17h2"/><path d="M7 8h10v8H7z"/>`,
		vehicle: `<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/>`,
		contraband: `<path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5M12 22V12"/>`,
		gear: `<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/>`,
	};
</script>

{#if items.length === 0}
	<EmptyState
		title="No Archive Data"
		description="The transaction log is currently empty. All future operations will be logged here."
	/>
{:else}
	<div class="history-list">
		{#each items as entry (entry.id)}
			<div
				class="history-card"
				class:is-failed={entry.status === "failed"}
			>
				<div class="entry-visual">
					<div class="image-wrapper">
						<img
							src={`${$inventoryImageBaseUrl}${entry.productImage}`}
							alt={entry.productName}
						/>
						<div class="category-tag">
							<svg
								viewBox="0 0 24 24"
								fill="none"
								stroke="currentColor"
								stroke-width="2"
							>
								{@html icons[entry.categoryId] || ""}
							</svg>
						</div>
					</div>
				</div>

				<div class="entry-info">
					<div class="info-header">
						<span class="product-name">{entry.productName}</span>
						<span class="timestamp"
							>{formatDate(entry.purchasedAt)}</span
						>
					</div>
					<div class="info-footer">
						<span class="category-name">{entry.categoryName}</span>
						<span class="rarity-pill rarity-{entry.rarity}"
							>{entry.rarity.toUpperCase()}</span
						>
						{#if entry.quantity > 1}
							<span class="qty-pill">QTY x{entry.quantity}</span>
						{/if}
						<div class="status-indicator">
							{#if entry.status === "success"}
								<svg
									viewBox="0 0 24 24"
									fill="none"
									stroke="currentColor"
									stroke-width="3"
								>
									<polyline points="20 6 9 17 4 12" />
								</svg>
								<span>CONFIRMED</span>
							{:else}
								<svg
									viewBox="0 0 24 24"
									fill="none"
									stroke="currentColor"
									stroke-width="3"
								>
									<line x1="18" y1="6" x2="6" y2="18" /><line
										x1="6"
										y1="6"
										x2="18"
										y2="18"
									/>
								</svg>
								<span>FAILED</span>
							{/if}
						</div>
					</div>
				</div>

				<div class="entry-price">
					<span class="price-label">AMOUNT PAID</span>
					<span class="price-value"
						>{formatPrice(entry.pricePaid)}</span
					>
				</div>

				<div class="card-accent"></div>
			</div>
		{/each}
	</div>
{/if}

<style>
	.history-list {
		display: grid;
		gap: 0.5rem;
		perspective: 1000px;
	}

	.history-card {
		position: relative;
		display: grid;
		grid-template-columns: 60px 1fr auto;
		align-items: center;
		background: linear-gradient(
			90deg,
			rgba(255, 255, 255, 0.01) 0%,
			transparent 100%
		);
		border: 1px solid rgba(255, 255, 255, 0.03);
		border-left: 2px solid var(--line-soft);
		border-radius: 4px;
		padding: 0.85rem 1.25rem;
		gap: 1.25rem;
		transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
		overflow: hidden;
	}

	.history-card:hover {
		background: linear-gradient(
			90deg,
			rgba(255, 255, 255, 0.03) 0%,
			transparent 100%
		);
		border-color: rgba(255, 255, 255, 0.08);
		border-left-color: var(--accent-primary);
		transform: translateX(6px);
	}

	.history-card.is-failed {
		border-left-color: var(--state-danger);
	}

	.history-card.is-failed:hover {
		border-left-color: var(--state-danger);
	}

	.entry-visual {
		position: relative;
		display: flex;
		justify-content: center;
	}

	.image-wrapper {
		width: 60px;
		height: 60px;
		background: radial-gradient(
			circle at center,
			rgba(255, 255, 255, 0.05),
			transparent
		);
		border: 1px solid rgba(255, 255, 255, 0.05);
		border-radius: 6px;
		padding: 6px;
		display: flex;
		align-items: center;
		justify-content: center;
		position: relative;
	}

	.image-wrapper img {
		width: 100%;
		height: 100%;
		object-fit: contain;
		filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.5));
	}

	.category-tag {
		position: absolute;
		bottom: -4px;
		right: -4px;
		width: 20px;
		height: 20px;
		background: var(--bg-surface);
		border: 1.5px solid var(--line-soft);
		border-radius: 6px;
		padding: 3.5px;
		color: var(--accent-primary);
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
	}

	.history-card.is-failed .category-tag {
		color: var(--state-danger);
	}

	.entry-info {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.info-header {
		display: flex;
		align-items: center;
		gap: 0.85rem;
	}

	.product-name {
		font-size: 1.05rem;
		font-weight: 700;
		color: var(--text-main);
		letter-spacing: -0.01em;
	}

	.timestamp {
		font-size: 0.72rem;
		color: var(--text-dim);
		font-weight: 600;
		text-transform: uppercase;
		background: rgba(255, 255, 255, 0.03);
		padding: 0.15rem 0.45rem;
		border-radius: 3px;
	}

	.info-footer {
		display: flex;
		align-items: center;
		gap: 1rem;
		flex-wrap: wrap;
	}

	.category-name {
		font-size: 0.65rem;
		color: var(--text-dim);
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.1em;
	}

	.rarity-pill {
		font-size: 0.56rem;
		font-weight: 700;
		letter-spacing: 0.1em;
		padding: 0.16rem 0.42rem;
		border-radius: 2px;
		border: 1px solid transparent;
		line-height: 1;
	}

	.rarity-pill.rarity-common {
		color: #c4c4c4;
		border-color: rgba(142, 142, 142, 0.35);
		background: rgba(142, 142, 142, 0.10);
	}

	.rarity-pill.rarity-uncommon {
		color: #8dde7e;
		border-color: rgba(93, 197, 74, 0.35);
		background: rgba(93, 197, 74, 0.10);
	}

	.rarity-pill.rarity-rare {
		color: #7aabf9;
		border-color: rgba(59, 130, 246, 0.35);
		background: rgba(59, 130, 246, 0.10);
	}

	.rarity-pill.rarity-epic {
		color: #c48afc;
		border-color: rgba(168, 85, 247, 0.35);
		background: rgba(168, 85, 247, 0.10);
	}

	.rarity-pill.rarity-legendary {
		color: #f0c84a;
		border-color: rgba(234, 179, 8, 0.38);
		background: rgba(234, 179, 8, 0.12);
	}

	.qty-pill {
		font-size: 0.56rem;
		font-weight: 700;
		letter-spacing: 0.09em;
		padding: 0.16rem 0.42rem;
		border-radius: 2px;
		border: 1px solid var(--line-soft);
		color: var(--text-main);
		background: rgba(255, 255, 255, 0.03);
		line-height: 1;
	}

	.status-indicator {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		font-size: 0.68rem;
		font-weight: 700;
		letter-spacing: 0.08em;
	}

	.status-indicator svg {
		width: 11px;
		height: 11px;
	}

	.history-card:not(.is-failed) .status-indicator {
		color: var(--accent-primary);
	}

	.history-card.is-failed .status-indicator {
		color: var(--state-danger);
	}

	.entry-price {
		text-align: right;
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding-left: 2rem;
		position: relative;
	}

	.entry-price::before {
		content: "";
		position: absolute;
		left: 0;
		top: 20%;
		bottom: 20%;
		width: 1px;
		background: linear-gradient(
			to bottom,
			transparent,
			var(--line-soft),
			transparent
		);
	}

	.price-label {
		font-size: 0.58rem;
		font-weight: 700;
		color: var(--text-dim);
		letter-spacing: 0.12em;
		text-transform: uppercase;
		margin-bottom: -0.1rem;
	}

	.price-value {
		font-size: 1.25rem;
		font-weight: 700;
		color: var(--text-main);
		font-family: inherit;
		letter-spacing: -0.02em;
	}

	.card-accent {
		position: absolute;
		right: 0;
		top: 0;
		bottom: 0;
		width: 3px;
		background: var(--accent-primary);
		opacity: 0;
		transform: scaleY(0.4);
		transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
	}

	.history-card:hover .card-accent {
		opacity: 0.6;
		transform: scaleY(0.8);
	}

	.history-card.is-failed .card-accent {
		background: var(--state-danger);
	}

	@media (max-width: 800px) {
		.history-card {
			grid-template-columns: auto 1fr;
			padding: 1rem;
		}
		.entry-price {
			grid-column: span 2;
			border-left: none;
			padding-left: 0;
			margin-top: 0.75rem;
			padding-top: 0.75rem;
			border-top: 1px solid var(--line-soft);
			flex-direction: row;
			justify-content: space-between;
			align-items: center;
		}
		.entry-price::before {
			display: none;
		}
	}
</style>
