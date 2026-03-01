<script lang="ts">
  interface Props {
    title: string;
    level: number;
    discountPercent: number;
    balance: number;
    progressRatio: number;
    cartItemCount: number;
    onToggleCart: () => void;
  }

  let {
    title,
    level,
    discountPercent,
    balance,
    progressRatio,
    cartItemCount,
    onToggleCart,
  }: Props = $props();
</script>

<header class="nexus-header">
  <div class="header-main">
    <div class="header-info">
      <h1 class="market-title">{title}</h1>
    </div>

    <div class="header-stats">
      <!-- Operator Stats -->
      <div class="compact-stat">
        <div class="stat-meta">
          <span class="meta-icon-wrap">
            <svg
              class="meta-icon"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <circle cx="8.5" cy="8" r="2.5" />
              <path d="M4 16a4.5 4.5 0 0 1 9 0" />
              <path d="M15.5 7h4.5M15.5 10h4.5M15.5 13h2.8" />
            </svg>
          </span>
          <span class="meta-label">ID: OPERATOR</span>
        </div>
        <div class="stat-body">
          <span class="stat-val">LVL {level}</span>
          <div class="mini-bar">
            <div class="bar-fill" style="width: {progressRatio * 100}%"></div>
          </div>
          <span class="pct-val">{Math.round(progressRatio * 100)}%</span>
        </div>
      </div>

      <!-- Modifiers -->
      <div class="compact-stat">
        <div class="stat-meta">
          <span class="meta-icon-wrap">
            <svg
              class="meta-icon"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M4 6h7M4 12h16M4 18h10" />
              <circle cx="14" cy="6" r="2" />
              <circle cx="8" cy="18" r="2" />
            </svg>
          </span>
          <span class="meta-label">MODIFIERS</span>
        </div>
        <div class="stat-body">
          <div class="perk-shorthand">
            <span class="shorthand-item green"
              >{discountPercent > 0 ? `-${discountPercent}%` : '0%'} <small>OFF</small></span
            >
          </div>
        </div>
      </div>

      <!-- Capital -->
      <div class="compact-stat highlight">
        <div class="stat-meta">
          <span class="meta-icon-wrap">
            <svg
              class="meta-icon"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <rect x="2.5" y="6" width="19" height="12" rx="2.2" />
              <path d="M2.5 10h19" />
              <circle cx="8" cy="14" r="1.2" />
              <path d="M15.2 14h3.3" />
            </svg>
          </span>
          <span class="meta-label">LIQUID CAPITAL</span>
        </div>
        <div class="stat-body">
          <span class="stat-val balance">${balance.toLocaleString()}</span>
        </div>
      </div>

      <button
        type="button"
        class="integrated-cart-btn"
        class:has-items={cartItemCount > 0}
        onclick={onToggleCart}
        aria-label="Open Cart"
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
        {#if cartItemCount > 0}
          <span class="cart-badge">{cartItemCount}</span>
        {/if}
      </button>
    </div>
  </div>
</header>

<style>
  .nexus-header {
    display: grid;
    gap: 1.25rem;
    margin-bottom: 2rem;
  }

  .header-main {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    align-items: center;
    gap: 2rem;
  }

  .header-info {
    min-width: 0;
    padding-right: 0.35rem;
  }

  .header-info h1 {
    margin: 0.1rem 0;
    font-size: clamp(1.02rem, 1.45vw, 1.35rem);
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0;
    color: var(--text-main);
    line-height: 1;
    white-space: nowrap;
  }

  .header-stats {
    display: flex;
    flex-wrap: wrap;
    gap: 0.8rem;
    justify-content: flex-end;
    align-items: stretch;
    min-width: 0;
  }

  .compact-stat {
    background: rgba(255, 255, 255, 0.015);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    padding: 0.6rem 1.25rem;
    min-width: 220px;
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
    transition:
      background 0.2s ease,
      border-color 0.2s ease;
  }

  .compact-stat:hover {
    background: rgba(255, 255, 255, 0.03);
    border-color: rgba(255, 255, 255, 0.08);
  }

  .compact-stat.highlight {
    border-color: rgba(255, 255, 255, 0.1);
    background:
      linear-gradient(
        180deg,
        rgba(255, 255, 255, 0.04) 0%,
        rgba(255, 255, 255, 0.02) 52%,
        rgba(255, 255, 255, 0.01) 100%
      ),
      rgba(255, 255, 255, 0.015);
    box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.04);
  }

  .compact-stat.highlight:hover {
    border-color: rgba(255, 255, 255, 0.14);
    background:
      linear-gradient(
        180deg,
        rgba(255, 255, 255, 0.055) 0%,
        rgba(255, 255, 255, 0.025) 52%,
        rgba(255, 255, 255, 0.012) 100%
      ),
      rgba(255, 255, 255, 0.015);
  }

  .compact-stat.highlight .stat-meta {
    opacity: 0.82;
  }

  .compact-stat.highlight .meta-icon {
    color: rgba(240, 240, 240, 0.82);
  }

  .compact-stat.highlight .meta-label {
    color: rgba(215, 215, 215, 0.72);
  }

  .compact-stat.highlight .stat-val.balance {
    color: #f2f2f2;
    letter-spacing: 0.015em;
    text-shadow: none;
  }

  .integrated-cart-btn {
    width: 58px;
    background: rgba(255, 255, 255, 0.02);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    display: grid;
    place-items: center;
    position: relative;
    cursor: pointer;
    transition: all 0.2s ease;
    color: var(--text-dim);
  }

  .integrated-cart-btn:hover {
    background: rgba(255, 255, 255, 0.04);
    border-color: var(--accent-primary);
    color: var(--accent-primary);
  }

  .integrated-cart-btn.has-items {
    border-color: var(--accent-border);
    color: var(--accent-primary);
    background: var(--accent-soft);
  }

  .integrated-cart-btn svg {
    width: 20px;
    height: 20px;
  }

  .cart-badge {
    position: absolute;
    top: 6px;
    right: 6px;
    background: var(--accent-primary);
    color: #000;
    font-size: 0.55rem;
    font-weight: 700;
    min-width: 16px;
    height: 16px;
    padding: 0 2px;
    border-radius: 3px;
    display: grid;
    place-items: center;
    box-shadow: 0 0 10px var(--accent-soft);
  }

  .stat-meta {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    opacity: 0.7;
  }

  .meta-icon {
    width: 12px;
    height: 12px;
    position: relative;
    z-index: 1;
  }

  .meta-icon-wrap {
    width: 16px;
    height: 16px;
    display: grid;
    place-items: center;
    border-radius: 3px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.06);
    color: var(--accent-primary);
  }

  .meta-label {
    font-size: 0.55rem;
    font-weight: 700;
    color: var(--text-dim);
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }

  .stat-body {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    width: 100%;
    justify-content: flex-start;
  }

  .stat-val {
    font-size: 0.95rem;
    font-weight: 700;
    color: var(--text-main);
    letter-spacing: 0.05em;
    white-space: nowrap;
    line-height: 1;
  }

  .mini-bar {
    flex: 1;
    height: 8px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 99px;
    overflow: hidden;
    position: relative;
  }

  .pct-val {
    font-size: 0.6rem;
    font-weight: 700;
    color: var(--text-dim);
    min-width: 28px;
    text-align: right;
  }

  .bar-fill {
    height: 100%;
    background: var(--accent-primary);
  }

  .perk-shorthand {
    display: flex;
    align-items: center;
    gap: 0.6rem;
  }

  .shorthand-item {
    font-size: 0.85rem;
    font-weight: 700;
  }

  .shorthand-item small {
    font-size: 0.5rem;
    opacity: 0.6;
    margin-left: 0.1rem;
    font-weight: 700;
  }

  .shorthand-item.green {
    color: var(--accent-primary);
  }

  @media (max-width: 1200px) {
    .header-main {
      grid-template-columns: 1fr;
    }
    .header-stats {
      flex-wrap: wrap;
    }
    .compact-stat {
      flex: 1;
    }
  }
</style>
