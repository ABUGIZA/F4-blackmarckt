<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';
	import { isNuiVisible } from '$lib/stores';
	import '../app.css';

	let { children } = $props();

	const accentStyle = `--accent-primary:#18d58f;--accent-hover:#22f5a6;--accent-soft:rgb(24 213 143 / 20%);--accent-border:rgb(24 213 143 / 45%);`;

	$effect(() => {
		if (typeof document === 'undefined') return;
		document.body.classList.toggle('nui-visible', $isNuiVisible);

		return () => {
			document.body.classList.remove('nui-visible');
		};
	});
</script>

<svelte:head>
	<title>Black Market UI</title>
	<link rel="icon" href={favicon} />
</svelte:head>

<div class="app-shell" class:is-hidden={!$isNuiVisible} style={accentStyle}>
	<div class="app-modal">
		{@render children()}
	</div>
</div>

<style>
	.app-shell.is-hidden {
		display: none;
	}
</style>
