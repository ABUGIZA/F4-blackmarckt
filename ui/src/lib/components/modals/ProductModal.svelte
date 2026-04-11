<script lang="ts">
	import type { Product } from "$lib/types";
	import { inventoryImageBaseUrl } from "$lib/stores";
	import ModalShell from "./ModalShell.svelte";
	import logo from "../../assets/logo.png";

	interface Props {
		open: boolean;
		product: Product | null;
		finalPrice: number;
		reputationDiscountPercent: number;
		userLevel: number;
		userBalance: number;
		userBlackMoney: number;
		marketOpen: boolean;
		offerSecondsRemaining: number | null;
		onClose: () => void;
		onBuy: (paymentMethod: 'normal' | 'black_money') => void;
		onAddToCart: (productId: string) => void;
	}

	let {
		open,
		product,
		finalPrice,
		reputationDiscountPercent,
		userLevel,
		userBalance,
		userBlackMoney,
		marketOpen,
		offerSecondsRemaining,
		onClose,
		onBuy,
		onAddToCart,
	}: Props = $props();

	let paymentMethod = $state<'normal' | 'black_money'>('normal');

	const formatPrice = (value: number) => `$${value.toLocaleString("en-US")}`;
	const isLocked = (requiredLevel: number, currentLevel: number) =>
		requiredLevel > currentLevel;

	let modalWrapper = $state<HTMLDivElement | null>(null);

	const getFocusableElements = () => {
		if (!modalWrapper) return [] as HTMLElement[];
		const selectors =
			'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';
		return Array.from(
			modalWrapper.querySelectorAll<HTMLElement>(selectors),
		).filter((element) => !element.hasAttribute("aria-hidden"));
	};

	const trapFocus = (event: KeyboardEvent) => {
		if (event.key !== "Tab") return;

		const focusable = getFocusableElements();
		if (focusable.length === 0) {
			event.preventDefault();
			modalWrapper?.focus();
			return;
		}

		const first = focusable[0];
		const last = focusable[focusable.length - 1];
		const active = document.activeElement as HTMLElement | null;

		if (event.shiftKey) {
			if (active === first || active === modalWrapper) {
				event.preventDefault();
				last.focus();
			}
			return;
		}

		if (active === last) {
			event.preventDefault();
			first.focus();
		}
	};

	const handleDialogKeydown = (event: KeyboardEvent) => {
		if (event.key === "Escape") {
			event.preventDefault();
			onClose();
			return;
		}

		trapFocus(event);
	};

	$effect(() => {
		if (!(open && product)) return;
		queueMicrotask(() => {
			const focusable = getFocusableElements();
			(focusable[0] ?? modalWrapper)?.focus();
		});
	});
</script>

{#if open && product}
	<div
		class="bm-modal-backdrop"
		role="presentation"
		onclick={(event) => event.target === event.currentTarget && onClose()}
	>
		<div
			class="bm-modal-wrapper"
			role="dialog"
			aria-modal="true"
			aria-label={product.name}
			tabindex="-1"
			bind:this={modalWrapper}
			onkeydown={handleDialogKeydown}
		>
			<ModalShell
				title=""
				label={product.rarity.toUpperCase()}
				labelColor={`var(--rarity-${product.rarity})`}
				maxWidth="740px"
			>
				<div class="product-layout">
					<!-- Hero Section -->
					<div class="hero-section">
						<div class="image-area">
							<div class="corner-accent top-left"></div>
							<div class="corner-accent top-right"></div>
							<div class="corner-accent bottom-left"></div>
							<div class="corner-accent bottom-right"></div>
							<img
								src={`${$inventoryImageBaseUrl}${product.image}`}
								alt={product.name}
							/>
						</div>

						<div class="info-area">
							<div class="header-block">
								<h2 class="product-name">{product.name}</h2>
								<p class="product-desc">
									{product.description}
								</p>
							</div>

							<div class="price-block">
								<div class="price-info">
									<span class="price-tag-label"
										>AUTHORIZED PRICE</span
									>
									<div class="price-display">
										<span class="currency">$</span>
										<h2 class="price-value">
											{finalPrice.toLocaleString("en-US")}
										</h2>
									</div>
								</div>

								<div class="badges-stack">
									<div
										class="status-badge"
										class:is-locked={isLocked(
											product.requiredLevel,
											userLevel,
										)}
									>
										<span class="dot"></span>
										{isLocked(
											product.requiredLevel,
											userLevel,
										)
											? "LEVEL RESTRICTED"
											: `LEVEL ${product.requiredLevel}+ AUTHORIZED`}
									</div>
									{#if product.offer && offerSecondsRemaining !== null && offerSecondsRemaining > 0}
										<div class="offer-badge">
											-{product.offer.discountPercentage}%
											ACTIVE OFFER
										</div>
									{/if}
								</div>
							</div>
						</div>
					</div>

					<!-- Technical Specs Grid -->
					<div class="specs-grid">
						<div class="spec-cell">
							<div class="spec-label">
								<svg
									viewBox="0 0 24 24"
									fill="none"
									stroke="currentColor"
									stroke-width="2.5"
									stroke-linecap="round"
									stroke-linejoin="round"
								>
									<line x1="12" y1="1" x2="12" y2="23"></line>
									<path
										d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"
									></path>
								</svg>
								BASE PRICE
							</div>
							<p class="spec-value">
								{formatPrice(product.basePrice)}
							</p>
						</div>
						<div class="spec-cell">
							<div class="spec-label">
								<div class="spec-icon">
									<img src={logo} alt="XP" />
								</div>
								REP GAIN
							</div>
							<p class="spec-value">
								+{product.reputationGain} XP
							</p>
						</div>
						<div class="spec-cell">
							<div class="spec-label">
								<svg
									viewBox="0 0 24 24"
									fill="none"
									stroke="currentColor"
									stroke-width="2.5"
									stroke-linecap="round"
									stroke-linejoin="round"
								>
									<path
										d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"
									></path>
									<line x1="7" y1="7" x2="7.01" y2="7"></line>
								</svg>
								DISCOUNT
							</div>
							<p class="spec-value">
								-{reputationDiscountPercent}%
							</p>
						</div>
						<div class="spec-cell">
							<div class="spec-label">
								<svg
									viewBox="0 0 24 24"
									fill="none"
									stroke="currentColor"
									stroke-width="2.5"
									stroke-linecap="round"
									stroke-linejoin="round"
								>
									<path
										d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"
									></path>
									<circle cx="12" cy="7" r="4"></circle>
								</svg>
								RANK STATUS
							</div>
							<p class="spec-value">LEVEL {userLevel}</p>
						</div>
					</div>
				</div>

				{#snippet footer()}
					<div class="modal-footer">
						<div class="modal-payment-selector">
							<button
								class="modal-pay-opt"
								class:active={paymentMethod === 'normal'}
								onclick={() => (paymentMethod = 'normal')}
							>
								<span class="modal-pay-name">Cash / Bank</span>
								<span class="modal-pay-bal">${userBalance.toLocaleString()}</span>
							</button>
							<button
								class="modal-pay-opt bm"
								class:active={paymentMethod === 'black_money'}
								onclick={() => (paymentMethod = 'black_money')}
							>
								<span class="modal-pay-name">Black Money</span>
								<span class="modal-pay-bal">${userBlackMoney.toLocaleString()}</span>
							</button>
						</div>
						<div class="modal-footer-actions">
							<button class="btn-cancel" onclick={onClose}
								>ABORT</button
							>
							<button
								class="btn-secondary"
								onclick={() => product && onAddToCart(product.id)}
								disabled={isLocked(
									product.requiredLevel,
									userLevel,
								) || !marketOpen}
							>
								ADD TO CART
							</button>
							<button
								class="btn-confirm"
								onclick={() => onBuy(paymentMethod)}
								disabled={isLocked(
									product.requiredLevel,
									userLevel,
								) || !marketOpen}
							>
								<span class="btn-text">CONFIRM ACQUISITION</span>
								<svg
									viewBox="0 0 24 24"
									fill="none"
									stroke="currentColor"
									stroke-width="3"
								>
									<path d="M5 12h14M12 5l7 7-7 7" />
								</svg>
							</button>
						</div>
					</div>
				{/snippet}
			</ModalShell>
		</div>
	</div>
{/if}

<style>
	.bm-modal-backdrop {
		position: fixed;
		inset: 0;
		background: rgba(4, 5, 5, 0.94);
		backdrop-filter: blur(16px);
		-webkit-backdrop-filter: blur(16px);
		display: grid;
		place-items: center;
		padding: 2rem;
		z-index: 1000;
	}

	.bm-modal-wrapper {
		width: 100%;
		display: flex;
		justify-content: center;
		animation: modalEntry 0.3s cubic-bezier(0.16, 1, 0.3, 1);
	}

	@keyframes modalEntry {
		from {
			opacity: 0;
			transform: translateY(10px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	.product-layout {
		display: grid;
		gap: 2.5rem;
		padding: 0.5rem 0;
	}

	/* Hero Section */
	.hero-section {
		display: grid;
		grid-template-columns: 220px 1fr;
		gap: 2.5rem;
		align-items: start;
	}

	.image-area {
		width: 220px;
		height: 220px;
		background: rgba(255, 255, 255, 0.015);
		border: 1px solid var(--line-soft);
		border-radius: 4px;
		display: grid;
		place-items: center;
		position: relative;
		transition: border-color 0.3s ease;
	}

	.image-area img {
		width: 160px;
		height: 160px;
		object-fit: contain;
		filter: drop-shadow(0 0 20px rgba(0, 0, 0, 0.5));
	}

	.info-area {
		display: grid;
		gap: 1.5rem;
		align-content: space-between;
		height: 100%;
	}

	.product-name {
		margin: 0;
		font-size: 1.8rem;
		font-weight: 700;
		color: var(--text-main);
		text-transform: uppercase;
		letter-spacing: -0.01em;
		line-height: 1.1;
	}

	.product-desc {
		margin: 0.6rem 0 0;
		font-size: 0.95rem;
		color: var(--text-muted);
		line-height: 1.6;
		max-width: 90%;
	}

	.price-block {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		padding-top: 1.5rem;
		border-top: 1px solid var(--line-soft);
	}

	.price-tag-label {
		font-size: 0.65rem;
		font-weight: 700;
		letter-spacing: 0.2em;
		color: var(--text-dim);
		text-transform: uppercase;
		margin-bottom: 0.4rem;
		display: block;
	}

	.price-display {
		display: flex;
		align-items: baseline;
		gap: 0.3rem;
	}

	.currency {
		font-size: 1.2rem;
		font-weight: 700;
		color: var(--accent-primary);
		opacity: 0.7;
	}

	.price-value {
		margin: 0;
		font-size: 2.4rem;
		font-weight: 700;
		color: var(--accent-primary);
		line-height: 1;
	}

	.badges-stack {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 0.6rem;
	}

	.status-badge {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		padding: 0.4rem 0.8rem;
		background: rgba(24, 213, 143, 0.08);
		border-radius: 2px;
		font-size: 0.65rem;
		font-weight: 700;
		color: var(--accent-primary);
		letter-spacing: 0.05em;
	}

	.status-badge.is-locked {
		background: rgba(255, 77, 77, 0.08);
		color: #ff4d4d;
	}

	.status-badge .dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: currentColor;
	}

	.offer-badge {
		font-size: 0.65rem;
		font-weight: 700;
		color: #eab308;
		background: rgba(234, 179, 8, 0.1);
		padding: 0.3rem 0.6rem;
		border-radius: 2px;
	}

	/* Specs Grid */
	.specs-grid {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 1rem;
	}

	.spec-cell {
		background: rgba(255, 255, 255, 0.02);
		border: 1px solid var(--line-soft);
		padding: 1rem;
		border-radius: 4px;
		transition: all 0.2s ease;
	}

	.spec-cell:hover {
		background: rgba(255, 255, 255, 0.04);
		border-color: var(--accent-border);
	}

	.spec-label {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.6rem;
		font-weight: 700;
		color: var(--text-dim);
		letter-spacing: 0.1em;
		margin-bottom: 0.4rem;
	}

	.spec-label svg,
	.spec-icon {
		width: 14px;
		height: 14px;
		opacity: 0.6;
		display: flex;
		align-items: center;
	}

	.spec-icon img {
		width: 100%;
		height: 100%;
		object-fit: contain;
		filter: brightness(0.8) sepia(1) hue-rotate(100deg) saturate(3); /* Tint it to match the green theme */
	}

	.spec-value {
		margin: 0;
		font-size: 1.1rem;
		font-weight: 700;
		color: var(--text-main);
	}

	/* Footer Actions */
	.modal-footer {
		display: grid;
		gap: 1rem;
		width: 100%;
	}

	.modal-payment-selector {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 0.6rem;
	}

	.modal-pay-opt {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0.55rem 0.85rem;
		background: rgba(255, 255, 255, 0.02);
		border: 1px solid var(--line-soft);
		border-radius: 3px;
		cursor: pointer;
		transition: all 0.2s ease;
		color: var(--text-muted);
	}

	.modal-pay-opt:hover {
		background: rgba(255, 255, 255, 0.04);
		border-color: rgba(255, 255, 255, 0.12);
	}

	.modal-pay-opt.active {
		border-color: var(--accent-primary);
		background: rgba(24, 213, 143, 0.06);
		color: var(--text-main);
	}

	.modal-pay-opt.bm.active {
		border-color: #a78bfa;
		background: rgba(139, 92, 246, 0.08);
	}

	.modal-pay-name {
		font-size: 0.65rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
	}

	.modal-pay-bal {
		font-size: 0.8rem;
		font-weight: 700;
		color: var(--accent-primary);
	}

	.modal-pay-opt.bm .modal-pay-bal {
		color: #a78bfa;
	}

	.modal-footer-actions {
		display: flex;
		gap: 1rem;
		justify-content: flex-end;
	}

	.btn-cancel {
		background: transparent;
		border: 1px solid var(--line-soft);
		color: var(--text-muted);
		padding: 0.75rem 1.5rem;
		font-size: 0.75rem;
		font-weight: 700;
		letter-spacing: 0.1em;
		cursor: pointer;
		border-radius: 2px;
		transition: all 0.2s ease;
	}

	.btn-cancel:hover {
		background: rgba(255, 77, 77, 0.05);
		border-color: rgba(255, 77, 77, 1);
		color: #ff4d4d;
	}

	.btn-secondary {
		background: rgba(255, 255, 255, 0.02);
		border: 1px solid var(--line-soft);
		color: var(--text-muted);
		padding: 0.75rem 1.5rem;
		font-size: 0.75rem;
		font-weight: 700;
		letter-spacing: 0.1em;
		cursor: pointer;
		border-radius: 2px;
		transition: all 0.2s ease;
	}

	.btn-secondary:hover:not(:disabled) {
		background: rgba(255, 255, 255, 0.05);
		border-color: var(--text-dim);
		color: var(--text-main);
	}

	.btn-secondary:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}

	.btn-confirm {
		background: var(--accent-primary);
		color: #020404;
		border: none;
		padding: 0.75rem 1.5rem;
		font-size: 0.75rem;
		font-weight: 700;
		letter-spacing: 0.05em;
		cursor: pointer;
		border-radius: 2px;
		display: flex;
		align-items: center;
		gap: 0.75rem;
		transition: all 0.2s ease;
	}

	.btn-confirm:hover:not(:disabled) {
		transform: translateY(-1px);
		filter: brightness(1.1);
	}

	.btn-confirm:disabled {
		background: var(--bg-canvas);
		color: var(--text-dim);
		cursor: not-allowed;
		border: 1px solid var(--line-soft);
	}

	.btn-confirm svg {
		width: 14px;
		height: 14px;
	}

	/* Corner Accents */
	.corner-accent {
		position: absolute;
		width: 12px;
		height: 12px;
		border: 1px solid var(--accent-primary);
		opacity: 0.3;
	}

	.top-left {
		top: -1px;
		left: -1px;
		border-right: none;
		border-bottom: none;
	}
	.top-right {
		top: -1px;
		right: -1px;
		border-left: none;
		border-bottom: none;
	}
	.bottom-left {
		bottom: -1px;
		left: -1px;
		border-right: none;
		border-top: none;
	}
	.bottom-right {
		bottom: -1px;
		right: -1px;
		border-left: none;
		border-top: none;
	}

	@media (max-width: 680px) {
		.hero-section {
			grid-template-columns: 1fr;
			text-align: center;
		}
		.image-area {
			margin: 0 auto;
		}
		.badges-stack {
			align-items: center;
		}
		.specs-grid {
			grid-template-columns: 1fr 1fr;
		}
		.price-block {
			flex-direction: column;
			align-items: center;
			gap: 1.5rem;
		}
	}
</style>
