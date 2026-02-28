import adapter from '@sveltejs/adapter-static';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		adapter: adapter({
			precompress: false,
			strict: false
		}),
		paths: {
			relative: true
		},
		prerender: {
			entries: ['/', '/market', '/history']
		}
	}
};

export default config;
