<script lang="ts">
    import {
        cart,
        calculateDiscountedTotal,
        calculateGlobalDiscountAmount,
        userState,
        inventoryImageBaseUrl
    } from "$lib/stores";
    import { SectionHeader, Button, Card } from "$lib/components/ui";

    interface Props {
        onBack: () => void;
        onCheckout: () => void;
        isCheckingOut?: boolean;
    }

    let { onBack, onCheckout, isCheckingOut = false }: Props = $props();

    const handleQuantityChange = (productId: string, delta: number) => {
        cart.updateQuantity(productId, delta);
    };

    const handleRemove = (productId: string) => {
        cart.removeItem(productId);
    };

    const handleCheckout = () => {
        if ($cart.length === 0 || isCheckingOut) return;
        onCheckout();
    };

    // Before Discount = strict sum of base prices
    const cartListTotal = $derived.by(() =>
        $cart.reduce(
            (total, item) => total + item.product.basePrice * item.quantity,
            0,
        ),
    );

    // Discount = one global modifier on the full base total (no double discounting)
    const cartSavings = $derived.by(() =>
        calculateGlobalDiscountAmount(
            cartListTotal,
            $userState.discountPercent,
        ),
    );

    // After Discount = Before Discount - Discount
    const cartFinalTotal = $derived.by(() =>
        calculateDiscountedTotal(cartListTotal, $userState.discountPercent),
    );
</script>

<div class="cart-view">
    <SectionHeader
        eyebrow="Purchase Queue"
        title="Your Shopping Cart"
        description="Review your selected items and confirm your purchase."
    >
        {#snippet actions()}
            <Button variant="soft" size="sm" onclick={onBack}>
                Back to Market
            </Button>
        {/snippet}
    </SectionHeader>

    <div class="cart-layout">
        <div class="cart-items">
            {#if $cart.length === 0}
                <Card class="empty-cart">
                    <div class="empty-content">
                        <svg
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.5"
                        >
                            <circle cx="8" cy="21" r="1" />
                            <circle cx="19" cy="21" r="1" />
                            <path
                                d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"
                            />
                        </svg>
                        <h3>YOUR CART IS EMPTY</h3>
                        <p>Browse the market and add items to your queue.</p>
                        <Button variant="primary" onclick={onBack}
                            >Open Market</Button
                        >
                    </div>
                </Card>
            {:else}
                <div class="items-list">
                    {#each $cart as item (item.product.id)}
                        <Card class="cart-item-card" padded={false}>
                            <div class="item-inner">
                                <div class="item-image">
                                    <img
                                        src={`${$inventoryImageBaseUrl}${item.product.image}`}
                                        alt={item.product.name}
                                    />
                                </div>
                                <div class="item-info">
                                    <div class="item-meta">
                                        <span class="item-cat"
                                            >{item.product.categoryId.toUpperCase()}</span
                                        >
                                        <span
                                            class="item-rarity rarity-{item.product.rarity}"
                                        >
                                            {item.product.rarity.toUpperCase()}
                                        </span>
                                    </div>
                                    <h4>{item.product.name}</h4>
                                    <p class="item-price">
                                        ${item.product.basePrice.toLocaleString()} per unit
                                    </p>
                                </div>
                                <div class="item-controls">
                                    <div class="quantity-picker">
                                        <button
                                            onclick={() =>
                                                handleQuantityChange(
                                                    item.product.id,
                                                    -1,
                                                )}
                                            aria-label="Decrease quantity"
                                        >
                                            <svg
                                                viewBox="0 0 24 24"
                                                fill="none"
                                                stroke="currentColor"
                                                stroke-width="3"
                                            >
                                                <path d="M5 12h14" />
                                            </svg>
                                        </button>
                                        <span class="qty">{item.quantity}</span>
                                        <button
                                            onclick={() =>
                                                handleQuantityChange(
                                                    item.product.id,
                                                    1,
                                                )}
                                            disabled={item.quantity >= 10}
                                            title={item.quantity >= 10 ? "Max limit reached" : "Increase quantity"}
                                            aria-label={item.quantity >= 10 ? "Max limit reached" : "Increase quantity"}
                                        >
                                            <svg
                                                viewBox="0 0 24 24"
                                                fill="none"
                                                stroke="currentColor"
                                                stroke-width="3"
                                            >
                                                <path d="M12 5v14M5 12h14" />
                                            </svg>
                                        </button>
                                    </div>
                                    <div class="subtotal">
                                        ${(
                                            item.product.basePrice * item.quantity
                                        ).toLocaleString()}
                                    </div>
                                    <button
                                        class="remove-btn"
                                        onclick={() =>
                                            handleRemove(item.product.id)}
                                        aria-label="Remove item"
                                    >
                                        <svg
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            stroke="currentColor"
                                            stroke-width="2.5"
                                        >
                                            <path
                                                d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"
                                            />
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        </Card>
                    {/each}
                </div>
            {/if}
        </div>

        <div class="cart-summary">
            <Card title="ORDER SUMMARY">
                <div class="summary-details">
                    <div class="summary-row">
                        <span>Before Discount</span>
                        <span class="before-val">
                            ${cartListTotal.toLocaleString()}
                        </span>
                    </div>
                    <div class="summary-row discount">
                        <span>Discount</span>
                        <span>- ${cartSavings.toLocaleString()}</span>
                    </div>
                    <div class="summary-divider"></div>
                    <div class="summary-row total">
                        <span>After Discount</span>
                        <span class="total-val"
                            >${cartFinalTotal.toLocaleString()}</span
                        >
                    </div>
                </div>

                {#snippet footer()}
                    <div class="checkout-actions">
                        <Button
                            variant="primary"
                            class="checkout-btn"
                            disabled={$cart.length === 0 || isCheckingOut}
                            onclick={handleCheckout}
                        >
                            CONFIRM PURCHASE
                        </Button>
                        <p class="balance-hint">
                            Remaining Balance: <span
                                class:low={$userState.balance < cartFinalTotal}
                                >${(
                                    $userState.balance - cartFinalTotal
                                ).toLocaleString()}</span
                            >
                        </p>
                    </div>
                {/snippet}
            </Card>
        </div>
    </div>
</div>

<style>
    .cart-view {
        display: grid;
        gap: 1.5rem;
        animation: cart-in 200ms ease;
    }

    .cart-view :global(.bm-section-header__copy) {
        gap: 0.42rem;
    }

    .cart-view :global(.bm-section-header__copy .eyebrow) {
        margin-bottom: 0.12rem;
    }

    @keyframes cart-in {
        from {
            opacity: 0;
            transform: translateX(10px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    .cart-layout {
        display: grid;
        grid-template-columns: 1fr 350px;
        gap: 1.5rem;
        align-items: start;
    }

    .items-list {
        display: grid;
        gap: 0.75rem;
    }

    .item-inner {
        display: grid;
        grid-template-columns: 80px 1fr auto;
        align-items: center;
        padding: 0.75rem 1rem;
        gap: 1.5rem;
    }

    .item-image {
        width: 80px;
        height: 80px;
        background: rgba(255, 255, 255, 0.02);
        border: 1px solid var(--line-soft);
        border-radius: 4px;
        display: grid;
        place-items: center;
    }

    .item-image img {
        width: 60px;
        height: 60px;
        object-fit: contain;
    }

    .item-info h4 {
        margin: 0;
        font-size: 1rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.02em;
    }

    .item-cat {
        font-size: 0.6rem;
        font-weight: 700;
        color: var(--text-dim);
        letter-spacing: 0.1em;
    }

    .item-meta {
        display: flex;
        align-items: center;
        gap: 0.45rem;
        margin-bottom: 0.18rem;
    }

    .item-rarity {
        font-size: 0.55rem;
        font-weight: 700;
        letter-spacing: 0.1em;
        padding: 0.14rem 0.4rem;
        border-radius: 2px;
        border: 1px solid transparent;
        color: var(--text-main);
    }

    .item-rarity.rarity-common {
        color: #c4c4c4;
        border-color: rgba(142, 142, 142, 0.36);
        background: rgba(142, 142, 142, 0.12);
    }

    .item-rarity.rarity-uncommon {
        color: #8dde7e;
        border-color: rgba(93, 197, 74, 0.34);
        background: rgba(93, 197, 74, 0.11);
    }

    .item-rarity.rarity-rare {
        color: #7aabf9;
        border-color: rgba(59, 130, 246, 0.34);
        background: rgba(59, 130, 246, 0.10);
    }

    .item-rarity.rarity-epic {
        color: #c48afc;
        border-color: rgba(168, 85, 247, 0.34);
        background: rgba(168, 85, 247, 0.10);
    }

    .item-rarity.rarity-legendary {
        color: #f0c84a;
        border-color: rgba(234, 179, 8, 0.38);
        background: rgba(234, 179, 8, 0.12);
    }

    .item-price {
        margin: 0.1rem 0 0;
        font-size: 0.75rem;
        color: var(--text-muted);
    }

    .original-price {
        text-decoration: line-through;
        text-decoration-thickness: 1px;
        text-decoration-color: rgba(148, 148, 148, 0.7);
        opacity: 0.55;
        margin-right: 0.2rem;
    }

    .item-controls {
        display: flex;
        align-items: center;
        gap: 2rem;
    }

    .quantity-picker {
        display: flex;
        align-items: center;
        background: rgba(0, 0, 0, 0.2);
        border: 1px solid var(--line-soft);
        border-radius: 4px;
        overflow: hidden;
    }

    .quantity-picker button {
        width: 32px;
        height: 32px;
        background: transparent;
        border: none;
        color: var(--text-muted);
        cursor: pointer;
        display: grid;
        place-items: center;
        transition: all 0.2s ease;
    }

    .quantity-picker button:hover:not(:disabled) {
        background: rgba(255, 255, 255, 0.05);
        color: var(--text-main);
    }

    .quantity-picker button:disabled {
        opacity: 0.3;
        cursor: not-allowed;
    }

    .quantity-picker button svg {
        width: 12px;
        height: 12px;
    }

    .qty {
        width: 40px;
        text-align: center;
        font-size: 0.9rem;
        font-weight: 700;
        color: var(--text-main);
        border-left: 1px solid var(--line-soft);
        border-right: 1px solid var(--line-soft);
    }

    .subtotal {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--accent-primary);
        min-width: 100px;
        text-align: right;
    }

    .remove-btn {
        background: transparent;
        border: none;
        color: var(--text-dim);
        cursor: pointer;
        padding: 4px;
        transition: color 0.2s ease;
    }

    .remove-btn:hover {
        color: #ff4d4d;
    }

    .remove-btn svg {
        width: 18px;
        height: 18px;
    }

    .summary-details {
        display: grid;
        gap: 0.75rem;
    }

    .summary-row {
        display: flex;
        justify-content: space-between;
        font-size: 0.85rem;
        font-weight: 700;
        color: var(--text-muted);
    }

    .summary-divider {
        height: 1px;
        background: var(--line-soft);
        margin: 0.25rem 0;
    }

    .before-val {
        color: var(--text-dim);
        text-decoration: line-through;
        text-decoration-thickness: 1px;
        text-decoration-color: rgba(148, 148, 148, 0.8);
    }

    .summary-row.discount {
        color: var(--accent-primary);
    }

    .total {
        font-size: 1.1rem;
        color: var(--text-main);
    }

    .total-val {
        color: var(--accent-primary);
        font-weight: 700;
    }

    .checkout-actions {
        display: grid;
        gap: 0.75rem;
    }

    :global(.checkout-btn) {
        width: 100%;
        padding: 1rem !important;
        font-size: 0.85rem !important;
    }

    .balance-hint {
        margin: 0;
        font-size: 0.7rem;
        text-align: center;
        font-weight: 700;
        color: var(--text-dim);
    }

    .balance-hint span.low {
        color: #ff4d4d;
    }

    :global(.empty-cart) {
        min-height: 400px;
        display: grid;
        place-items: center;
    }

    .empty-content {
        text-align: center;
        display: grid;
        gap: 1rem;
        place-items: center;
        max-width: 300px;
    }

    .empty-content svg {
        width: 64px;
        height: 64px;
        color: var(--text-dim);
        opacity: 0.5;
    }

    .empty-content h3 {
        margin: 0;
        font-size: 1.1rem;
        letter-spacing: 0.05em;
        color: var(--text-main);
    }

    .empty-content p {
        margin: 0;
        font-size: 0.8rem;
        color: var(--text-muted);
        line-height: 1.5;
    }

    @media (max-width: 1200px) {
        .cart-layout {
            grid-template-columns: 1fr;
        }
    }
</style>
