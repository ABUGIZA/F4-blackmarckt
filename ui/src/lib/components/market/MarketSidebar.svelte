<script lang="ts">
	export interface SidebarCategoryItem {
		id: string;
		name: string;
		count: number;
	}

	interface Props {
		categories: SidebarCategoryItem[];
		activeCategoryId: string;
		onSelect: (categoryId: string) => void;
		onShowHistory: () => void;
	}

	let {
		categories,
		activeCategoryId,
		onSelect,
		onShowHistory,
	}: Props = $props();

	const icons: Record<string, string> = {
		all: `<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/>`,
		explosives: `<path d="M19 5L5 19M19 19L5 5" stroke-width="2.5"/><circle cx="12" cy="12" r="8"/>`,
		tools: `<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.77 3.77Z"/>`,
		electronics: `<rect x="2" y="2" width="20" height="20" rx="2" ry="2"/><path d="M7 2v2M12 2v2M17 2v2M7 20v2M12 20v2M17 20v2M2 7h2M2 12h2M2 17h2M20 7h2M20 12h2M20 17h2"/><path d="M7 8h10v8H7z"/>`,
		vehicle: `<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/>`,
		contraband: `<path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5M12 22V12"/>`,
		gear: `<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/>`,
	};
</script>

<aside class="nexus-sidebar">
	<nav class="sidebar-nav">
		{#each categories as item (item.id)}
			<button
				type="button"
				class="sidebar-item"
				class:is-active={activeCategoryId === item.id}
				onclick={() => onSelect(item.id)}
			>
				<div class="item-icon">
					<svg
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
					>
						{@html icons[item.id] || ""}
					</svg>
				</div>
				<div class="item-content">
					<span class="item-name">{item.name}</span>
					<span class="item-count">{item.count} ASSETS</span>
				</div>
			</button>
		{/each}
	</nav>

	<footer class="sidebar-footer">
		<button type="button" class="history-btn" onclick={onShowHistory}>
			<svg
				viewBox="0 0 24 24"
				fill="none"
				stroke="currentColor"
				stroke-width="2"
			>
				<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
				<path d="M3 3v5h5" />
				<path d="M12 7v5l4 2" />
			</svg>
			TRANSACTION HISTORY
		</button>
	</footer>
</aside>

<style>
	.nexus-sidebar {
		display: grid;
		grid-template-rows: 1fr auto;
		background: transparent;
		padding-top: 1.5rem;
		border-right: 1px solid var(--line-soft);
	}

	.sidebar-nav {
		padding: 0 0.75rem;
		display: grid;
		align-content: start;
		gap: 0.4rem;
		overflow-y: auto; /* Internal scroll if many categories */
	}

	.sidebar-item {
		display: flex;
		align-items: center;
		gap: 1rem;
		width: 100%;
		padding: 0.75rem 0.75rem;
		background: transparent;
		border: none;
		border-radius: 4px;
		color: var(--text-muted);
		cursor: pointer;
		position: relative;
		transition: all 0.2s ease;
	}

	.sidebar-item::before {
		content: "";
		position: absolute;
		left: 0;
		top: 0;
		bottom: 0;
		width: 4px;
		background: var(--accent-primary);
		border-radius: 0 2px 2px 0;
		opacity: 0;
		transform: scaleY(0);
		transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
	}

	.sidebar-item:hover {
		color: var(--text-main);
		background: rgba(255, 255, 255, 0.04);
	}

	.sidebar-item.is-active {
		color: var(--accent-primary);
		background: var(--accent-soft);
	}

	.sidebar-item.is-active::before {
		opacity: 1;
		transform: scaleY(1);
	}

	.item-icon {
		width: 18px;
		height: 18px;
		opacity: 0.6;
		transition: opacity 0.2s ease;
	}

	.sidebar-item:hover .item-icon,
	.sidebar-item.is-active .item-icon {
		opacity: 1;
	}

	.item-content {
		display: flex;
		flex-direction: column;
		text-align: left;
	}

	.item-name {
		font-size: 0.8rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	.item-count {
		font-size: 0.55rem;
		font-weight: 600;
		color: var(--text-dim);
	}

	.sidebar-footer {
		padding: 1rem 0.75rem;
		display: grid;
		gap: 0.4rem;
		background: rgba(0, 0, 0, 0.2);
		position: relative;
	}

	.sidebar-footer::before {
		content: "";
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 1px;
		background: var(--line-soft);
		pointer-events: none;
	}

	.history-btn {
		display: flex;
		align-items: center;
		justify-content: flex-start;
		gap: 0.85rem;
		width: 100%;
		padding: 0.8rem 1rem;
		background: rgba(255, 255, 255, 0.02);
		border: 1px solid transparent;
		border-radius: 4px;
		color: var(--text-muted);
		font-size: 0.7rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
		cursor: pointer;
		position: relative;
		clip-path: polygon(4% 0, 100% 0, 100% 75%, 96% 100%, 0 100%, 0 25%);
	}

	.history-btn:hover {
		color: var(--text-main);
		background: rgba(255, 255, 255, 0.05);
	}

	.history-btn svg {
		width: 16px;
		height: 16px;
		opacity: 0.5;
		transition: opacity 0.2s ease;
	}

	.history-btn:hover svg {
		opacity: 1;
	}

	@media (max-width: 900px) {
		.nexus-sidebar {
			border-right: 0;
			border-bottom: 1px solid var(--line-soft);
		}

		.sidebar-nav {
			grid-template-columns: repeat(2, minmax(0, 1fr));
			padding: 0.5rem;
		}
	}

	@media (max-width: 720px) {
		.sidebar-nav {
			grid-template-columns: 1fr;
		}
	}
</style>
