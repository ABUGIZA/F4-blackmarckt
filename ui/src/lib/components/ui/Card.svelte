<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    title?: string;
    subtitle?: string;
    padded?: boolean;
    children?: Snippet;
    footer?: Snippet;
    class?: string;
    style?: string;
  }

  let {
    title,
    subtitle,
    padded = true,
    class: className = "",
    style = "",
    children,
    footer,
  }: Props = $props();
</script>

<article class={`bm-card ${padded ? "is-padded" : ""} ${className}`} {style}>
  <div class="corner-accent top-left"></div>
  <div class="corner-accent top-right"></div>

  {#if title || subtitle}
    <header class="bm-card__header">
      {#if title}
        <h3>{title}</h3>
      {/if}
      {#if subtitle}
        <p>{subtitle}</p>
      {/if}
    </header>
  {/if}

  <div class="bm-card__body">
    {@render children?.()}
  </div>

  {#if footer}
    <footer class="bm-card__footer">
      {@render footer()}
    </footer>
  {/if}
</article>

<style>
  .bm-card {
    background: var(--bg-panel);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    display: grid;
    gap: 0.75rem;
    position: relative;
    overflow: hidden;
    transition:
      border-color 0.2s ease,
      box-shadow 0.2s ease;
  }

  .bm-card:hover {
    border-color: var(--accent-border);
    background: rgba(255, 255, 255, 0.03);
  }

  .corner-accent {
    position: absolute;
    width: 4px;
    height: 4px;
    border: 1px solid var(--accent-primary);
    opacity: 0.3;
    pointer-events: none;
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

  .bm-card:hover .corner-accent {
    opacity: 1;
    width: 8px;
    height: 8px;
  }

  .bm-card.is-padded {
    padding: 0.92rem;
  }

  .bm-card__header {
    display: grid;
    gap: 0.25rem;
  }

  h3 {
    margin: 0;
    font-size: 0.9rem;
    font-weight: 600;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    color: var(--text-main);
  }

  p {
    margin: 0;
    color: var(--text-muted);
    font-size: 0.86rem;
  }

  .bm-card__body {
    display: grid;
    gap: 0.75rem;
  }

  .bm-card__footer {
    padding-top: 0.72rem;
    border-top: 1px solid var(--line-soft);
  }
</style>
