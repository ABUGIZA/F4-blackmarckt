import { derived, writable, get } from 'svelte/store';
import type { Category, MarketRuntimeStatus, MarketSortBy, Product } from '$lib/types';

export type CategoryFilterId = 'all' | string;

export interface SidebarCategory {
	id: CategoryFilterId;
	name: string;
	count: number;
}

// ── Writable stores populated from server snapshot ──────────────────────

export const serverProducts = writable<Product[]>([]);
export const serverCategories = writable<Category[]>([]);
export const inventoryImageBaseUrl = writable('https://cfx-nui-ox_inventory/web/images/');

const marketMode = writable<'always_open' | 'scheduled'>('always_open');
const marketSchedule = writable<{ startTime: string; endTime: string } | null>(null);

// ── Sync helper called when server data arrives ─────────────────────────

export const syncMarketDataFromServer = (snapshot: {
	products?: Product[];
	categories?: Category[];
	mode?: string;
	schedule?: { startTime: string; endTime: string };
	imageBaseUrl?: string;
}) => {
	if (Array.isArray(snapshot.products) && snapshot.products.length > 0) {
		serverProducts.set(snapshot.products);
	}
	if (Array.isArray(snapshot.categories) && snapshot.categories.length > 0) {
		serverCategories.set(snapshot.categories);
	}
	if (snapshot.mode) {
		marketMode.set(snapshot.mode === 'scheduled' ? 'scheduled' : 'always_open');
	}
	if (snapshot.schedule) {
		marketSchedule.set(snapshot.schedule);
	}
	if (typeof snapshot.imageBaseUrl === 'string' && snapshot.imageBaseUrl.trim().length > 0) {
		const base = snapshot.imageBaseUrl.endsWith('/')
			? snapshot.imageBaseUrl
			: `${snapshot.imageBaseUrl}/`;
		inventoryImageBaseUrl.set(base);
	}
};

// ── Clock / schedule helpers ────────────────────────────────────────────

const DAY_SECONDS = 24 * 60 * 60;

const parseClockSeconds = (value: string): number | null => {
	const [hourRaw, minuteRaw] = value.split(':');
	const hour = Number(hourRaw);
	const minute = Number(minuteRaw);

	if (!Number.isInteger(hour) || !Number.isInteger(minute)) return null;
	if (hour < 0 || hour > 23) return null;
	if (minute < 0 || minute > 59) return null;

	return hour * 3600 + minute * 60;
};

const getSecondsUntilTarget = (targetSeconds: number, nowSeconds: number): number =>
	targetSeconds >= nowSeconds ? targetSeconds - nowSeconds : DAY_SECONDS - nowSeconds + targetSeconds;

const evaluateMarketStatus = (timestampMs: number, mode: string, schedule: { startTime: string; endTime: string } | null): MarketRuntimeStatus => {
	if (mode === 'always_open' || !schedule) {
		return { isOpen: true, secondsUntilChange: null, nextTransition: null };
	}

	const now = new Date(timestampMs);
	const nowSeconds = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
	const startSeconds = parseClockSeconds(schedule.startTime);
	const endSeconds = parseClockSeconds(schedule.endTime);

	if (startSeconds === null || endSeconds === null || startSeconds === endSeconds) {
		return { isOpen: true, secondsUntilChange: null, nextTransition: null };
	}

	const crossMidnight = startSeconds > endSeconds;

	const isOpen = crossMidnight
		? nowSeconds >= startSeconds || nowSeconds < endSeconds
		: nowSeconds >= startSeconds && nowSeconds < endSeconds;

	const secondsUntilChange = isOpen
		? getSecondsUntilTarget(endSeconds, nowSeconds)
		: getSecondsUntilTarget(startSeconds, nowSeconds);

	return {
		isOpen,
		secondsUntilChange,
		nextTransition: isOpen ? 'close' : 'open'
	};
};

// ── Public stores ───────────────────────────────────────────────────────

export const searchQuery = writable('');
export const sortBy = writable<MarketSortBy>('featured');
export const activeCategoryId = writable<CategoryFilterId>('all');
export const clockTimestamp = writable(Date.now());

let ticker: ReturnType<typeof setInterval> | null = null;

export const startMarketClock = () => {
	if (ticker) return;
	ticker = setInterval(() => {
		clockTimestamp.set(Date.now());
	}, 1000);
};

export const stopMarketClock = () => {
	if (!ticker) return;
	clearInterval(ticker);
	ticker = null;
};

export const marketStatus = derived(
	[clockTimestamp, marketMode, marketSchedule],
	([$clockTimestamp, $mode, $schedule]) => evaluateMarketStatus($clockTimestamp, $mode, $schedule)
);

export const categories = derived([searchQuery, serverCategories, serverProducts], ([$searchQuery, $cats, $prods]): SidebarCategory[] => {
	const keyword = $searchQuery.trim().toLowerCase();
	const sorted = [...$cats].sort((a, b) => a.order - b.order);

	const countByCategory = new Map<string, number>();
	for (const category of sorted) {
		countByCategory.set(category.id, 0);
	}

	for (const product of $prods) {
		if (!product.name.toLowerCase().includes(keyword)) continue;
		countByCategory.set(product.categoryId, (countByCategory.get(product.categoryId) ?? 0) + 1);
	}

	const sidebarCategories: SidebarCategory[] = sorted.map((category) => ({
		id: category.id,
		name: category.name,
		count: countByCategory.get(category.id) ?? 0
	}));

	const allCount = sidebarCategories.reduce((sum, item) => sum + item.count, 0);
	return [{ id: 'all', name: 'All Items', count: allCount }, ...sidebarCategories];
});

export const filteredProducts = derived(
	[searchQuery, activeCategoryId, sortBy, clockTimestamp, serverProducts],
	([$searchQuery, $activeCategoryId, $sortBy, $clockTimestamp, $prods]) => {
		const keyword = $searchQuery.trim().toLowerCase();
		const list = $prods.filter((product) => {
			const matchesSearch = product.name.toLowerCase().includes(keyword);
			const matchesCategory = $activeCategoryId === 'all' || product.categoryId === $activeCategoryId;
			return matchesSearch && matchesCategory;
		});

		const sorted = [...list];
		if ($sortBy === 'featured') {
			sorted.sort((a, b) => {
				const aOffer = Number(isOfferActive(a, $clockTimestamp));
				const bOffer = Number(isOfferActive(b, $clockTimestamp));
				return bOffer - aOffer || a.requiredLevel - b.requiredLevel;
			});
		}
		if ($sortBy === 'price_asc') sorted.sort((a, b) => a.basePrice - b.basePrice);
		if ($sortBy === 'price_desc') sorted.sort((a, b) => b.basePrice - a.basePrice);
		if ($sortBy === 'level_asc') sorted.sort((a, b) => a.requiredLevel - b.requiredLevel);
		return sorted;
	}
);

export const marketTitle = derived(
	[activeCategoryId, serverCategories],
	([$activeCategoryId, $cats]) => {
		if ($activeCategoryId === 'all') return 'All Market Items';
		const cat = $cats.find((c) => c.id === $activeCategoryId);
		return `${cat?.name ?? 'Category'} Items`;
	}
);

export const marketDescription = derived(
	[activeCategoryId, serverCategories],
	([$activeCategoryId, $cats]) => {
		if ($activeCategoryId === 'all') return 'Browse all available inventory. Use search and sorting to find the best deal quickly.';
		const cat = $cats.find((c) => c.id === $activeCategoryId);
		return `Focused view for ${cat?.name ?? 'selected category'}.`;
	}
);

export const selectCategory = (value: CategoryFilterId) => {
	activeCategoryId.set(value);
};

export const isOfferActive = (product: Product, nowTimestamp = Date.now()): boolean => {
	if (!product.offer) return false;
	return new Date(product.offer.endTimestamp).getTime() > nowTimestamp;
};

export const getOfferSecondsRemaining = (product: Product, nowTimestamp = Date.now()): number | null => {
	if (!product.offer) return null;
	const delta = Math.floor((new Date(product.offer.endTimestamp).getTime() - nowTimestamp) / 1000);
	return Math.max(0, delta);
};

export const getCategoryName = (categoryId: string): string => {
	const cats = get(serverCategories);
	const cat = cats.find((c) => c.id === categoryId);
	return cat?.name ?? categoryId;
};

export const calculateOfferOnlyPrice = (
	product: Product,
	nowTimestamp = Date.now()
): number => {
	const offerDiscount = isOfferActive(product, nowTimestamp)
		? product.basePrice * ((product.offer?.discountPercentage ?? 0) / 100)
		: 0;
	const rawPrice = Math.max(0, product.basePrice - offerDiscount);
	let finalPrice = Math.floor(rawPrice);

	if (rawPrice > 0 && product.basePrice > 0 && finalPrice < 1) {
		finalPrice = 1;
	}

	return finalPrice;
};

const normalizeWholePrice = (value: number): number => {
	const raw = Math.max(0, Number(value) || 0);
	let normalized = Math.floor(raw);

	if (raw > 0 && normalized < 1) {
		normalized = 1;
	}

	return normalized;
};

export const calculateGlobalDiscountAmount = (
	baseTotal: number,
	discountPercent: number
): number => {
	const safeTotal = normalizeWholePrice(baseTotal);
	if (safeTotal <= 0) return 0;

	const safePercent = Math.max(0, Number(discountPercent) || 0);
	const rawDiscount = safeTotal * (safePercent / 100);

	// Floor so fractional discounts that don't reach $1 are correctly $0.
	let discount = Math.floor(rawDiscount);
	discount = Math.min(discount, safeTotal - 1);

	return Math.max(0, discount);
};

export const calculateDiscountedTotal = (
	baseTotal: number,
	discountPercent: number
): number => {
	const safeTotal = normalizeWholePrice(baseTotal);
	if (safeTotal <= 0) return 0;

	const discount = calculateGlobalDiscountAmount(safeTotal, discountPercent);
	return Math.max(0, safeTotal - discount);
};

export const calculateFinalPrice = (
	product: Product,
	reputationDiscountPercent: number,
	nowTimestamp = Date.now()
): number => {
	void nowTimestamp;
	return calculateDiscountedTotal(product.basePrice, reputationDiscountPercent);
};
