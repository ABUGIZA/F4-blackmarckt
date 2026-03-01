export interface ProductOffer {
	discountPercentage: number;
	endTimestamp: string;
}

export type ProductRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';

export interface Product {
	id: string;
	name: string;
	description: string;
	image: string;
	categoryId: string;
	basePrice: number;
	requiredLevel: number;
	reputationGain: number;
	rarity: ProductRarity;
	offer?: ProductOffer;
}
