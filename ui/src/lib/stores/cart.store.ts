import { writable, derived } from 'svelte/store';
import type { Product } from '$lib/types';

export interface CartItem {
    product: Product;
    quantity: number;
    priceAtAddition: number;
}

const createCartStore = () => {
    const { subscribe, set, update } = writable<CartItem[]>([]);

    return {
        subscribe,
        addItem: (product: Product, price: number) => {
            update((items) => {
                const existingIndex = items.findIndex((item) => item.product.id === product.id);
                if (existingIndex !== -1) {
                    const newItems = [...items];
                    newItems[existingIndex].quantity = Math.min(10, newItems[existingIndex].quantity + 1);
                    return newItems;
                }
                return [...items, { product, quantity: 1, priceAtAddition: price }];
            });
        },
        removeItem: (productId: string) => {
            update((items) => items.filter((item) => item.product.id !== productId));
        },
        updateQuantity: (productId: string, delta: number) => {
            update((items) => {
                return items.map((item) => {
                    if (item.product.id === productId) {
                        const newQuantity = Math.max(1, Math.min(10, item.quantity + delta));
                        return { ...item, quantity: newQuantity };
                    }
                    return item;
                });
            });
        },
        clearCart: () => set([])
    };
};

export const cart = createCartStore();

export const cartTotal = derived(cart, ($cart) => {
    return $cart.reduce((total, item) => total + item.product.basePrice * item.quantity, 0);
});

export const cartCount = derived(cart, ($cart) => {
    return $cart.reduce((count, item) => count + item.quantity, 0);
});
