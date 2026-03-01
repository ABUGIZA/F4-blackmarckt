import { writable } from 'svelte/store';

export type NotificationType =
	| 'purchase_success'
	| 'purchase_fail'
	| 'level_up'
	| 'market_closed'
	| 'offer_expired'
	| 'cart_add'
	| 'cart_empty';

export interface NotificationEntry {
	id: string;
	type: NotificationType;
	message: string;
	createdAt: string;
}

const detectFiveMEnvironment = () =>
	typeof window !== 'undefined' && typeof (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName === 'function';

export const activeProductId = writable<string | null>(null);
export const notifications = writable<NotificationEntry[]>([]);
export const isNuiVisible = writable(!detectFiveMEnvironment());

export const openProduct = (productId: string) => {
	activeProductId.set(productId);
};

export const closeProduct = () => {
	activeProductId.set(null);
};

export const pushNotification = (type: NotificationType, message: string, autoDismissMs = 3000) => {
	const id = `n_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
	const entry: NotificationEntry = {
		id,
		type,
		message,
		createdAt: new Date().toISOString()
	};

	notifications.update((list) => [entry, ...list]);

	if (autoDismissMs > 0) {
		setTimeout(() => {
			notifications.update((list) => list.filter((item) => item.id !== id));
		}, autoDismissMs);
	}
};

export const dismissNotification = (id: string) => {
	notifications.update((list) => list.filter((item) => item.id !== id));
};

export const setNuiVisible = (value: boolean) => {
	isNuiVisible.set(value);
};

export const clearNotifications = () => {
	notifications.set([]);
};
