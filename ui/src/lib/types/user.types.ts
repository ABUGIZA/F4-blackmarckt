export interface LevelTier {
	level: number;
	minReputation: number;
	discountPercent: number;
}

export interface UserState {
	currentReputation: number;
	currentLevel: number;
	discountPercent: number;
	balance: number;
}

export interface UserProgress {
	currentLevelMinReputation: number;
	nextLevelMinReputation: number | null;
	nextLevel: number | null;
	nextLevelDiscountPercent: number | null;
	reputationToNextLevel: number;
	progressRatio: number;
}

export interface UserViewState extends UserState {
	progress: UserProgress;
}
