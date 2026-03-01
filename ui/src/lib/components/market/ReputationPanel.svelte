<script lang="ts">
	interface Props {
		level: number;
		reputation: number;
		discountPercent: number;
		progressRatio: number;
		nextLevel: number | null;
		nextLevelDiscountPercent: number | null;
		reputationToNextLevel: number;
	}

	let {
		level,
		reputation,
		discountPercent,
		progressRatio,
		nextLevel,
		nextLevelDiscountPercent,
		reputationToNextLevel,
	}: Props = $props();

	const progressPercent = $derived(Math.round(progressRatio * 100));
</script>

<section class="rep-panel" aria-label="Reputation progression">
	<div class="rep-head">
		<div class="rep-title">
			<p>Reputation Progress</p>
			<h2>Level {level}</h2>
		</div>
		<div class="rep-metrics">
			<span>REP {reputation}</span>
			<span>Discount -{discountPercent}%</span>
		</div>
	</div>

	<div class="rep-bar-wrap">
		<div class="rep-bar-fill" style={`width: ${progressPercent}%;`}></div>
	</div>

	<div class="rep-footer">
		{#if nextLevel !== null}
			<p>
				{reputationToNextLevel} rep to Level {nextLevel}
				{#if nextLevelDiscountPercent !== null}
					(Next discount: -{nextLevelDiscountPercent}%)
				{/if}
			</p>
		{:else}
			<p>Max level reached.</p>
		{/if}
		<span>{progressPercent}%</span>
	</div>
</section>

<style>
	.rep-panel {
		display: grid;
		gap: 0.6rem;
		padding: 1rem;
		border-radius: 2px;
		border: 1px solid var(--line-soft);
		background: rgba(0, 0, 0, 0.4);
		position: relative;
		overflow: hidden;
	}

	.rep-panel::before {
		content: "";
		position: absolute;
		top: 0;
		right: 0;
		width: 150px;
		height: 150px;
		background: radial-gradient(
			circle at top right,
			rgba(0, 242, 255, 0.08),
			transparent 70%
		);
		pointer-events: none;
	}

	.rep-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.6rem;
		flex-wrap: wrap;
	}

	.rep-title p {
		margin: 0;
		color: var(--text-dim);
		font-size: 0.74rem;
		text-transform: uppercase;
		letter-spacing: 0.09em;
	}

	.rep-title h2 {
		margin: 0.18rem 0 0;
		font-size: 1.02rem;
		letter-spacing: -0.01em;
	}

	.rep-metrics {
		display: inline-flex;
		gap: 0.55rem;
		flex-wrap: wrap;
	}

	.rep-metrics span {
		padding: 0.2rem 0.6rem;
		border-radius: 2px;
		background: rgba(255, 255, 255, 0.03);
		border: 1px solid var(--line-soft);
		color: var(--text-main);
		font-size: 0.7rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	.rep-bar-wrap {
		height: 4px;
		border-radius: 1px;
		overflow: hidden;
		background: rgba(255, 255, 255, 0.05);
		border: none;
	}

	.rep-bar-fill {
		height: 100%;
		background: var(--accent-primary);
		box-shadow: 0 0 10px var(--accent-glow);
		transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
	}

	.rep-footer {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.6rem;
		color: var(--text-muted);
		font-size: 0.8rem;
	}

	.rep-footer p {
		margin: 0;
	}
</style>
