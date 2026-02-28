import { derived, writable } from 'svelte/store';
import type { LevelTier, UserState, UserViewState } from '$lib/types';

interface ServerPlayerSnapshot {
	reputation: number;
	balance?: number;
	bank?: number;
	cash?: number;
}

// Writable – populated from server snapshot (Config.Market.levels)
const serverLevels = writable<LevelTier[]>([
	{ level: 0, minReputation: 0, discountPercent: 0 }
]);

const DEFAULT_REPUTATION = 0;

const sortLevels = (levels: LevelTier[]): LevelTier[] =>
	[...levels].sort((a, b) => a.level - b.level);

const resolveLevelByReputation = (reputation: number, levels: LevelTier[]): LevelTier => {
	const sorted = sortLevels(levels);
	let result = sorted[0];
	for (const tier of sorted) {
		if (reputation >= tier.minReputation) result = tier;
	}
	return result;
};

const resolveNextLevel = (level: number, levels: LevelTier[]): LevelTier | null => {
	const sorted = sortLevels(levels);
	return sorted.find((tier) => tier.level === level + 1) ?? null;
};

const baseState = writable<UserState>({
	currentReputation: DEFAULT_REPUTATION,
	currentLevel: 0,
	discountPercent: 0,
	balance: 0
});

export const userState = derived([baseState, serverLevels], ([$baseState, $levels]): UserViewState => {
	const currentTier = resolveLevelByReputation($baseState.currentReputation, $levels);
	const nextTier = resolveNextLevel(currentTier.level, $levels);
	const currentMin = currentTier.minReputation;
	const nextMin = nextTier?.minReputation ?? null;
	const reputationToNextLevel = nextMin === null ? 0 : Math.max(0, nextMin - $baseState.currentReputation);
	const progressRatio =
		nextMin === null
			? 1
			: Math.min(1, Math.max(0, ($baseState.currentReputation - currentMin) / (nextMin - currentMin)));

	return {
		currentReputation: $baseState.currentReputation,
		currentLevel: currentTier.level,
		discountPercent: currentTier.discountPercent,
		balance: $baseState.balance,
		progress: {
			currentLevelMinReputation: currentMin,
			nextLevelMinReputation: nextMin,
			nextLevel: nextTier?.level ?? null,
			nextLevelDiscountPercent: nextTier?.discountPercent ?? null,
			reputationToNextLevel,
			progressRatio
		}
	};
});

export const syncLevelsFromServer = (levels: LevelTier[]) => {
	if (Array.isArray(levels) && levels.length > 0) {
		serverLevels.set(levels);
	}
};

export const addReputation = (amount: number) => {
	baseState.update((state) => ({ ...state, currentReputation: Math.max(0, state.currentReputation + amount) }));
};

export const setReputation = (value: number) => {
	baseState.update((state) => ({ ...state, currentReputation: Math.max(0, value) }));
};

export const addBalance = (amount: number) => {
	baseState.update((state) => ({ ...state, balance: Math.max(0, state.balance + amount) }));
};

export const setBalance = (value: number) => {
	baseState.update((state) => ({ ...state, balance: Math.max(0, value) }));
};

export const syncUserStateFromServer = (snapshot: ServerPlayerSnapshot) => {
	const normalizedReputation = Math.max(0, Math.trunc(snapshot.reputation ?? DEFAULT_REPUTATION));
	const resolvedBalance =
		typeof snapshot.balance === 'number' ? snapshot.balance : (snapshot.bank ?? 0) + (snapshot.cash ?? 0);

	baseState.update((state) => ({
		...state,
		currentReputation: normalizedReputation,
		balance: Math.max(0, Math.trunc(resolvedBalance))
	}));
};

export const resetUserState = () => {
	baseState.set({
		currentReputation: DEFAULT_REPUTATION,
		currentLevel: 0,
		discountPercent: 0,
		balance: 0
	});
};
