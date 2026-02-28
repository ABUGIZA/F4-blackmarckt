export type MarketMode = 'always_open' | 'scheduled';
export type MarketSortBy = 'featured' | 'price_asc' | 'price_desc' | 'level_asc';

export interface MarketSchedule {
	startTime: string;
	endTime: string;
}

export interface Category {
	id: string;
	name: string;
	icon: string;
	order: number;
	requiredLevel?: number;
}

export interface MarketRuntimeStatus {
	isOpen: boolean;
	secondsUntilChange: number | null;
	nextTransition: 'open' | 'close' | null;
}
