import { derived, get, writable } from 'svelte/store';
import type { Product } from '$lib/types';

export type PurchaseStatus = 'success' | 'failed';

export interface HistoryEntry {
	id: string;
	productId: string;
	productName: string;
	categoryId: string;
	rarity: Product['rarity'];
	quantity: number;
	pricePaid: number;
	status: PurchaseStatus;
	purchasedAt: string;
}

const entriesStore = writable<HistoryEntry[]>([]);

export const historyEntries = derived(entriesStore, ($entriesStore) =>
	[...$entriesStore].sort((a, b) => new Date(b.purchasedAt).getTime() - new Date(a.purchasedAt).getTime())
);

export const addHistoryEntry = (
	product: Product,
	pricePaid: number,
	status: PurchaseStatus,
	quantity = 1
) => {
	const safeQuantity = Math.max(1, Math.trunc(quantity));
	const entry: HistoryEntry = {
		id: `h_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
		productId: product.id,
		productName: product.name,
		categoryId: product.categoryId,
		rarity: product.rarity,
		quantity: safeQuantity,
		pricePaid,
		status,
		purchasedAt: new Date().toISOString()
	};

	entriesStore.update((entries) => [entry, ...entries]);
};

export const clearHistory = () => {
	entriesStore.set([]);
};

export const setHistoryEntries = (entries: HistoryEntry[]) => {
	entriesStore.set(
		(entries ?? []).map((entry) => ({
			...entry,
			quantity: Math.max(1, Math.trunc(entry.quantity ?? 1))
		}))
	);
};

export const getHistoryPage = (page: number, pageSize: number): { items: HistoryEntry[]; total: number; totalPages: number } => {
	const snapshot = get(historyEntries);

	const total = snapshot.length;
	const totalPages = Math.max(1, Math.ceil(total / pageSize));
	const safePage = Math.min(Math.max(page, 1), totalPages);
	const start = (safePage - 1) * pageSize;
	const items = snapshot.slice(start, start + pageSize);

	return {
		items,
		total,
		totalPages
	};
};
