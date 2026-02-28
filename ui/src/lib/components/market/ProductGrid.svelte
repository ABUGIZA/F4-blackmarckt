<script lang="ts">
  import { Card, EmptyState } from "$lib/components/ui";
  import { inventoryImageBaseUrl } from "$lib/stores";

  export interface ProductGridItem {
    id: string;
    name: string;
    description: string;
    image: string;
    categoryName: string;
    requiredLevel: number;
    rarity: string;
    offerPercentage?: number;
    offerSecondsRemaining?: number | null;
    locked: boolean;
    finalPrice: number;
  }

  interface Props {
    items: ProductGridItem[];
    marketOpen: boolean;
    onOpen: (productId: string) => void;
    onAddToCart: (productId: string) => void;
  }

  let { items, marketOpen, onOpen, onAddToCart }: Props = $props();

  const formatPrice = (value: number) => `$${value.toLocaleString("en-US")}`;
</script>

{#if items.length === 0}
  <EmptyState
    title="No items found"
    description="Try another search keyword or switch to a different category from the sidebar."
  />
{:else}
  <div class="products-grid">
    {#each items as product (product.id)}
      <Card
        class="product-card rarity-{product.rarity} {product.locked
          ? 'is-locked'
          : ''}"
        padded={false}
      >
        <div
          class="card-inner"
          style="--rarity-color: var(--rarity-{product.rarity})"
        >
          <!-- Rarity and Price Header -->
          <div class="card-header">
            <div class="rarity-tag rarity-{product.rarity}">
              {product.rarity.toUpperCase()}
            </div>
            <div class="price-pill">
              {formatPrice(product.finalPrice)}
            </div>
          </div>

          <button
            type="button"
            class="image-button"
            aria-label="View details for {product.name}"
            disabled={!marketOpen}
            onclick={() => onOpen(product.id)}
          >
            <div class="product-image-wrap">
              <img
                src={`${$inventoryImageBaseUrl}${product.image}`}
                alt={product.name}
                loading="lazy"
              />
              {#if product.locked}
                <div class="lock-overlay">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                  </svg>
                  <span class="lock-text"
                    >REQUIRES LEVEL {product.requiredLevel}</span
                  >
                </div>
              {/if}
            </div>
          </button>

          <div class="product-info">
            <div class="info-top">
              <span class="cat-label">{product.categoryName}</span>
              <h3>{product.name}</h3>
            </div>
            <p class="product-description">{product.description}</p>
          </div>

          <div class="card-actions">
            <button
              class="buy-button"
              aria-label="Purchase {product.name}"
              disabled={!marketOpen || product.locked}
              onclick={() => onOpen(product.id)}
            >
              {marketOpen
                ? product.locked
                  ? "LOCKED"
                  : "PURCHASE ITEM"
                : "MARKET CLOSED"}
            </button>
            <button
              class="cart-btn"
              aria-label="Add {product.name} to cart"
              disabled={!marketOpen || product.locked}
              onclick={() => onAddToCart(product.id)}
            >
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5"
              >
                <circle cx="8" cy="21" r="1" />
                <circle cx="19" cy="21" r="1" />
                <path
                  d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"
                />
              </svg>
            </button>
          </div>
        </div>
      </Card>
    {/each}
  </div>
{/if}

<style>
  .products-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 0.8rem;
  }

  :global(article.bm-card.product-card) {
    transition:
      border-color 0.24s ease,
      box-shadow 0.24s ease,
      transform 0.24s ease;
  }

  :global(article.bm-card.product-card:hover) {
    border-color: rgba(24, 213, 143, 0.2);
    box-shadow:
      0 0 0 1px rgba(24, 213, 143, 0.14),
      0 4px 10px rgba(0, 0, 0, 0.26);
    transform: none;
  }

  :global(article.bm-card.product-card.is-locked:hover) {
    border-color: var(--line-soft);
    box-shadow:
      0 0 0 1px rgba(255, 255, 255, 0.06),
      0 8px 18px rgba(0, 0, 0, 0.42);
    transform: none;
  }

  .card-inner {
    display: flex;
    flex-direction: column;
    padding: 0.75rem;
    gap: 0.75rem;
    position: relative;
    isolation: isolate;
    transition: background 0.3s ease;
    background: linear-gradient(
      180deg,
      rgba(255, 255, 255, 0.02) 0%,
      rgba(0, 0, 0, 0.2) 100%
    );
    overflow: hidden;
  }

  .card-inner > * {
    position: relative;
    z-index: 1;
  }

  /* Rarity aura removed — only the tag label shows rarity color */
  .card-inner::before {
    content: none;
  }

  .card-inner::after {
    content: none;
  }

  :global(.product-card.is-locked) .card-inner::before {
    content: none;
  }

  :global(.product-card.is-locked) .card-inner::after {
    content: none;
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .rarity-tag {
    font-size: 0.55rem;
    font-weight: 700;
    letter-spacing: 0.1em;
    padding: 0.22rem 0.5rem;
    border-radius: 3px;
    border: 1px solid transparent;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
  }

  .rarity-tag.rarity-common {
    color: #c4c4c4;
    background: rgba(142, 142, 142, 0.15);
    border-color: rgba(142, 142, 142, 0.4);
  }

  .rarity-tag.rarity-uncommon {
    color: #8dde7e;
    background: rgba(93, 197, 74, 0.15);
    border-color: rgba(93, 197, 74, 0.4);
  }

  .rarity-tag.rarity-rare {
    color: #7aabf9;
    background: rgba(59, 130, 246, 0.15);
    border-color: rgba(59, 130, 246, 0.4);
  }

  .rarity-tag.rarity-epic {
    color: #c48afc;
    background: rgba(168, 85, 247, 0.15);
    border-color: rgba(168, 85, 247, 0.4);
  }

  .rarity-tag.rarity-legendary {
    color: #f0c84a;
    background: rgba(234, 179, 8, 0.15);
    border-color: rgba(234, 179, 8, 0.4);
  }

  .price-pill {
    font-size: 0.95rem;
    font-weight: 700;
    color: var(--accent-primary);
  }

  .product-image-wrap {
    height: 140px;
    background: rgba(0, 0, 0, 0.4);
    border: 1px solid var(--line-soft);
    display: grid;
    place-items: center;
    overflow: hidden;
    position: relative;
    border-radius: 2px;
  }

  .product-image-wrap::before {
    content: "";
    position: absolute;
    inset: 0;
    background:
      radial-gradient(circle at 50% 45%, rgba(255, 255, 255, 0.02), transparent 72%),
      linear-gradient(
        180deg,
        rgba(255, 255, 255, 0.02) 0%,
        rgba(0, 0, 0, 0.34) 100%
      );
    opacity: 0.12;
    transition: opacity 0.3s ease;
  }

  .product-image-wrap img {
    width: 100px;
    height: 100px;
    object-fit: contain;
    transition: transform 0.3s ease;
  }

  .lock-overlay {
    position: absolute;
    inset: 0;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(4px);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }

  .lock-overlay svg {
    width: 24px;
    height: 24px;
    opacity: 0.5;
  }

  .lock-text {
    font-size: 0.6rem;
    font-weight: 700;
    letter-spacing: 0.1em;
    color: var(--text-dim);
  }

  .image-button {
    padding: 0;
    border: 0;
    background: transparent;
    cursor: pointer;
    width: 100%;
  }

  .product-info {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
  }

  .info-top {
    display: flex;
    flex-direction: column;
  }

  .cat-label {
    font-size: 0.55rem;
    color: var(--text-dim);
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
  }

  .product-info h3 {
    margin: 0;
    font-size: 0.95rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.02em;
  }

  .product-description {
    margin: 0;
    font-size: 0.7rem;
    color: var(--text-muted);
    line-height: 1.4;
    height: 2.8em;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;
  }

  .card-actions {
    display: flex;
    gap: 0.5rem;
    margin-top: auto;
  }

  .buy-button {
    flex: 1;
    background: var(--accent-primary);
    color: #000;
    border: none;
    border-radius: 2px;
    padding: 0.6rem;
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    cursor: pointer;
    transition: filter 0.2s ease;
  }

  .buy-button:hover:not(:disabled) {
    filter: brightness(1.1);
  }

  .buy-button:disabled {
    background: var(--bg-canvas);
    color: var(--text-dim);
    cursor: not-allowed;
    border: 1px solid var(--line-soft);
  }

  .cart-btn {
    width: 42px;
    background: rgba(255, 255, 255, 0.02);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    display: grid;
    place-items: center;
    cursor: pointer;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    color: var(--text-dim);
    clip-path: polygon(15% 0, 100% 0, 100% 85%, 85% 100%, 0 100%, 0 15%);
  }

  .cart-btn:hover:enabled {
    background: rgba(24, 213, 143, 0.05);
    border-color: var(--accent-border);
    color: var(--accent-primary);
    transform: translateY(-2px);
  }

  .cart-btn:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }

  .cart-btn svg {
    width: 18px;
    height: 18px;
  }

  @media (max-width: 1400px) {
    .products-grid {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }
  }

  @media (max-width: 1080px) {
    .products-grid {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }
  }

  @media (max-width: 720px) {
    .products-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
