import { redirect } from '@sveltejs/kit';
import { base } from '$app/paths';

export const prerender = false;

export function load() {
	throw redirect(307, `${base}/market`);
}
