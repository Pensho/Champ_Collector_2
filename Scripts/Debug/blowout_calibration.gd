extends SceneTree
## Calibration harness for the Blowout design pillar (Concept_Document.md section 1.1).
##
## Answers how large a Combined_Modifier must be, and how many independent factors it
## takes, for a burst to reach the target contrast ratio over a basic skill. Mirrors
## `Skills.MitigatedDamage` rather than re-deriving it, so the numbers reflect the
## implemented formula.
##
## Run: godot --headless -s Scripts/Debug/blowout_calibration.gd

# Sorcerer preset: Mysticism 100, its basic skill Arc Lash scales 1.0 on Mysticism.
const CASTER_SCALED_BASE: float = 100.0

# Boss presets, as [name, Health attribute, Defence]. Actual hit points are the Health
# attribute times GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER. These are the balanced,
# playtested bosses; the newer catalog entries are excluded as untuned.
const BOSSES: Array = [
	["Troll", 300.0, 120.0],
	["Vael", 300.0, 90.0],
	["Obsidian Stallion", 330.0, 100.0],
	["Ulfrac", 270.0, 75.0],
	["Bor Bulwark", 280.0, 280.0],
]

# Fraction of a boss's hit points the burst should account for (Concept 1.1.1).
const BURST_SHARE_OF_BOSS: float = 0.7

const FACTOR_SIZES: Array[float] = [1.25, 1.5, 2.0, 3.0]
const FACTOR_COUNTS: Array[int] = [2, 3, 4, 5, 6, 8]
const TARGET_RATIOS: Array[float] = [30.0, 50.0]


func _initialize() -> void:
	print("=== Blowout calibration ===")
	print("Caster scaled aggregate (basic skill, no modifiers): %.0f" % CASTER_SCALED_BASE)
	print("Minimum damage percent: %.2f\n" % GameBalance.MINIMUM_DMG_PERCENT)

	_ReportBaselines()
	_ReportPlacementComparison()
	_ReportFactorRequirements()
	_ReportDefenceIgnoreSweep()
	_ReportHealthImplications()
	quit()


## Damage as `Skills.MitigatedDamage` computes it, with no critical hit and no random roll.
func _Damage(p_scaled_aggregate: float, p_effective_defence: float,
		p_final_multiplier: float = 1.0) -> float:
	var damage_ratio: float = (
			p_scaled_aggregate / (p_effective_defence + p_scaled_aggregate + 1.0))
	var mitigation: float = (
			GameBalance.MINIMUM_DMG_PERCENT
			+ ((1.0 - GameBalance.MINIMUM_DMG_PERCENT) * damage_ratio))
	return mitigation * p_scaled_aggregate * p_final_multiplier


## A boss's hit points, as `BattleResolver` computes them from the Health attribute.
func _HitPoints(p_health_attribute: float) -> float:
	return p_health_attribute * float(GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER)


func _ReportBaselines() -> void:
	print("--- Baseline basic skill, no modifiers ---")
	print("(three champions acting each round, all at basic-skill output)")
	for boss in BOSSES:
		var hit_points: float = _HitPoints(boss[1])
		var damage: float = _Damage(CASTER_SCALED_BASE, boss[2])
		var rounds: float = hit_points / (damage * 3.0)
		print("%-20s Defence %3.0f  %5.0f hit points -> %5.1f damage/hit (%.1f%%), %.1f rounds"
				% [boss[0], boss[2], hit_points, damage, 100.0 * damage / hit_points, rounds])
	print("")


## The modifier can multiply the caster's scaled aggregate (where the existing
## trait and ramp multipliers apply) or the final damage. The placements differ:
## the aggregate also feeds the mitigation ratio, so boosting it raises mitigation
## as well — superlinear at first, then saturating as mitigation approaches 1.
func _ReportPlacementComparison() -> void:
	print("--- Modifier placement: on the scaled aggregate vs on final damage ---")
	var defence: float = BOSSES[0][2]
	var baseline: float = _Damage(CASTER_SCALED_BASE, defence)
	print("%-10s %14s %10s %14s %10s" % ["Modifier", "on aggregate", "ratio", "on final", "ratio"])
	for modifier in [2.0, 5.0, 10.0, 33.0, 100.0, 1000.0]:
		var on_aggregate: float = _Damage(CASTER_SCALED_BASE * modifier, defence)
		var on_final: float = _Damage(CASTER_SCALED_BASE, defence, modifier)
		print("%9.0fx %14.0f %9.1fx %14.0f %9.1fx"
				% [modifier, on_aggregate, on_aggregate / baseline, on_final, on_final / baseline])
	print("")


func _ReportFactorRequirements() -> void:
	print("--- Independent factors needed to reach a target contrast ratio ---")
	var defence: float = BOSSES[0][2]
	print("(modifier applied to the scaled aggregate; against %s, Defence %.0f)"
			% [BOSSES[0][0], defence])
	var baseline: float = _Damage(CASTER_SCALED_BASE, defence)

	print("%-8s %s" % ["", "resulting contrast ratio by factor count"])
	var header: String = "%-8s" % "factor"
	for count in FACTOR_COUNTS:
		header += "%9d" % count
	print(header)
	for size in FACTOR_SIZES:
		var row: String = "%-8s" % ("%.2fx" % size)
		for count in FACTOR_COUNTS:
			var modifier: float = pow(size, float(count))
			var damage: float = _Damage(CASTER_SCALED_BASE * modifier, defence)
			row += "%8.1fx" % (damage / baseline)
		print(row)

	print("")
	for target in TARGET_RATIOS:
		var needed: float = _RequiredAggregateMultiplier(target, defence, baseline)
		print("Target %.0fx needs a %.1fx aggregate multiplier:" % [target, needed])
		for size in FACTOR_SIZES:
			var count: float = log(needed) / log(size)
			print("    %.2fx factors -> %.1f of them" % [size, count])
	print("")


## Smallest multiplier on the scaled aggregate that reaches `p_target` times baseline,
## found by bisection. Returns -1.0 when the target is unreachable at any multiplier.
func _RequiredAggregateMultiplier(
		p_target: float, p_defence: float, p_baseline: float) -> float:
	var low: float = 1.0
	var high: float = 1.0e6
	if(_Damage(CASTER_SCALED_BASE * high, p_defence) / p_baseline < p_target):
		return -1.0
	for _iteration in 200:
		var middle: float = (low + high) * 0.5
		if(_Damage(CASTER_SCALED_BASE * middle, p_defence) / p_baseline < p_target):
			low = middle
		else:
			high = middle
	return high


func _ReportDefenceIgnoreSweep() -> void:
	print("--- Defense_Ignore_Factor, at a 33x aggregate multiplier ---")
	var defence: float = BOSSES[0][2]
	var baseline: float = _Damage(CASTER_SCALED_BASE, defence)
	for ignore_factor in [1.0, 0.75, 0.5, 0.25, 0.0]:
		var damage: float = _Damage(CASTER_SCALED_BASE * 33.0, defence * ignore_factor)
		print("    %.2f -> %7.0f damage (%.1fx)" % [ignore_factor, damage, damage / baseline])
	print("")


func _ReportHealthImplications() -> void:
	print("--- Burst against current boss hit points, and the Health attribute it implies ---")
	print("(a burst should land as %.0f%% of a boss, per Concept 1.1.1)"
			% (100.0 * BURST_SHARE_OF_BOSS))
	for boss in BOSSES:
		var baseline: float = _Damage(CASTER_SCALED_BASE, boss[2])
		var hit_points: float = _HitPoints(boss[1])
		print("%s (Health attribute %.0f = %.0f hit points):" % [boss[0], boss[1], hit_points])
		for target in TARGET_RATIOS:
			var burst: float = baseline * target
			var needed_attribute: float = (
					burst / BURST_SHARE_OF_BOSS / float(GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER))
			print("    %3.0fx burst = %6.0f damage = %4.0f%% of it; wants Health %5.0f (%.1fx current)"
					% [target, burst, 100.0 * burst / hit_points,
					needed_attribute, needed_attribute / boss[1]])
	print("")
