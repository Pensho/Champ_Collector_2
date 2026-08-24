class_name BlowoutCalibration extends SceneTree
## Calibration harness for the Blowout design pillar (Concept_Document.md section 1.1).
##
## Answers how large a Combined_Modifier must be, and how many independent factors it
## takes, for a burst to reach the target contrast ratio over a basic skill. Mirrors
## `Skills.MitigatedDamage` rather than re-deriving it, so the numbers reflect the
## implemented formula.
##
## Run via Tests/manual/blowout_calibration_report.gd, NOT the bare `-s` entry point below —
## Skills.MitigatedDamageUnrounded transitively pulls in Character (through Skills's other
## static helpers), and a bare `-s` script's static dependency graph cannot reach
## Character.new() before its own compile step runs (see team_corpus_sweep.gd's header for
## the full explanation):
##   Tests/run_tests.sh -gtest=res://Tests/manual/blowout_calibration_report.gd -gexit

# Sorcerer preset: Mysticism 100, its basic skill Arc Lash scales 1.0 on Mysticism.
const CASTER_SCALED_BASE: float = 100.0
const CASTER_SCALED_ATTRIBUTE: Types.Attribute = Types.Attribute.Mysticism

# Boss presets, as [name, Health attribute, Defence, Knowledge]. Actual hit points are the
# Health attribute times GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER. These are the balanced,
# playtested bosses; the newer catalog entries are excluded as untuned. Knowledge blunts
# incoming critical damage (Concept_Document.md 3.2.1 #4); Troll and Obsidian Stallion read
# their real preset values (Data/Character_Enemy_Variants/{Troll,Obsidian_Stallion}.tres),
# the other three have no preset in the game and take the Troll's Knowledge as a stand-in.
const BOSSES: Array = [
	["Troll", 300.0, 120.0, 10.0],
	["Vael", 300.0, 90.0, 10.0],
	["Obsidian Stallion", 330.0, 100.0, 50.0],
	["Ulfrac", 270.0, 75.0, 10.0],
	["Bor Bulwark", 280.0, 280.0, 10.0],
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
	_ReportGearCeiling()
	quit()


## Damage as `Skills.MitigatedDamageUnrounded` computes it, with no critical hit and no
## random roll: p_final_multiplier stands in for MitigatedDamage's crit_multiplier parameter,
## which is just a generic post-mitigation multiplier when crit is neutralized this way. Uses
## the unrounded core (not Skills.MitigatedDamage's own int(ceil(...))) because these reports
## compose ratios of ratios — rounding each intermediate damage value first introduces a
## quantization artifact the real single-roll formula does not have.
static func _Damage(p_scaled_aggregate: float, p_effective_defence: float,
		p_final_multiplier: float = 1.0) -> float:
	return Skills.MitigatedDamageUnrounded(p_effective_defence, p_scaled_aggregate, p_final_multiplier, 1.0)


## Public entry point: the contrast ratio (Concept_Document.md 1.1.2) an arbitrary,
## possibly heterogeneous list of independent factors on the scaled aggregate produces —
## e.g. a composed team's mixed bucket values — generalizing _ReportFactorRequirements's
## former uniform pow(size, count) shortcut to any Array[float]. Scripts/Debug/burst_reachability.gd
## does NOT call this — it calls Skills.MitigatedDamage directly against its own already-composed
## CombinedDamageModifier.Product(), which is a single factor rather than a list of factors.
static func ContrastRatioForFactors(
		p_factors: Array[float], p_scaled_aggregate: float, p_defence: float) -> float:
	var modifier: float = 1.0
	for factor in p_factors:
		modifier *= factor
	var baseline: float = _Damage(p_scaled_aggregate, p_defence)
	var burst: float = _Damage(p_scaled_aggregate * modifier, p_defence)
	return burst / baseline


## A boss's hit points, as `BattleResolver` computes them from the Health attribute.
static func _HitPoints(p_health_attribute: float) -> float:
	return p_health_attribute * float(GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER)


## Static (not an _initialize()-only instance method) so Tests/manual/blowout_calibration_report.gd
## can call the five reports directly through a GUT entry path, without instantiating a SceneTree.
static func _ReportBaselines() -> void:
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
static func _ReportPlacementComparison() -> void:
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


static func _ReportFactorRequirements() -> void:
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
			var factors: Array[float] = []
			factors.resize(count)
			factors.fill(size)
			var ratio: float = ContrastRatioForFactors(factors, CASTER_SCALED_BASE, defence)
			row += "%8.1fx" % ratio
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
static func _RequiredAggregateMultiplier(
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


static func _ReportDefenceIgnoreSweep() -> void:
	print("--- Defense_Ignore_Factor, at a 33x aggregate multiplier ---")
	var defence: float = BOSSES[0][2]
	var baseline: float = _Damage(CASTER_SCALED_BASE, defence)
	for ignore_factor in [1.0, 0.75, 0.5, 0.25, 0.0]:
		var damage: float = _Damage(CASTER_SCALED_BASE * 33.0, defence * ignore_factor)
		print("    %.2f -> %7.0f damage (%.1fx)" % [ignore_factor, damage, damage / baseline])
	print("")


static func _ReportHealthImplications() -> void:
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


## Ceiling bonus to one attribute from a single item of `p_rarity`, fully upgraded
## (Game_Balance.MAX_ITEM_LEVEL times) with every point landing on that attribute.
## `Equipment.Upgrade()` only ever picks among attributes the item already carries
## (`Scripts/Gear/equipment.gd:55-65`), so an item rolled purely into one attribute at
## `EquipmentPreset.Setup()` stays purely that attribute through every later upgrade.
static func _ItemCeilingBonus(p_rarity: Types.Rarity) -> int:
	var rarity_value: int = int(p_rarity)
	var setup_bonus: int = GameBalance.ITEM_ATTRIBUTE_PER_RARITY * rarity_value
	var upgrade_bonus: int = (
			(GameBalance.ITEM_UPGRADE_FLAT_BONUS + rarity_value) * GameBalance.MAX_ITEM_LEVEL)
	return setup_bonus + upgrade_bonus


## Sizes gear's channel 1 ceiling (Concept_Document.md 3.3.1's gear verdict): every slot
## Game_Balance.ITEM_TYPE_ATTRIBUTES
## defines, at Legendary rarity and fully upgraded, rolled entirely into
## CASTER_SCALED_ATTRIBUTE wherever that slot's pool allows it. Slots with no entry in
## ITEM_TYPE_ATTRIBUTES (Trinket and the six flexibility slots) carry no attribute pool
## in code at all — reported as excluded from the loadout, not as a zero contribution,
## since Equipment.Upgrade() cannot even run on one today.
## Print-only, like the other reports in this file: a growing ceiling is a balance signal
## to look at, not a hard failure, so this is not asserted against a fixed threshold.
static func _ReportGearCeiling() -> void:
	print("--- Gear ceiling: fully-rolled, fully-upgraded Legendary loadout ---")
	var attribute_name: String = Types.Attribute.keys()[CASTER_SCALED_ATTRIBUTE]
	var per_item: int = _ItemCeilingBonus(Types.Rarity.Legendary)
	print("Per-item ceiling at Legendary, rolled and fully upgraded into one attribute: %d"
			% per_item)

	var slot_names: Array = Types.Slot.keys()
	var modeled_slots: Array = GameBalance.ITEM_TYPE_ATTRIBUTES.keys()
	var gear_bonus: int = 0
	for slot in modeled_slots:
		var pool: Array = GameBalance.ITEM_TYPE_ATTRIBUTES[slot]
		if(pool.has(CASTER_SCALED_ATTRIBUTE)):
			gear_bonus += per_item
			print("    %-10s can roll %s -> contributes %d"
					% [slot_names[slot], attribute_name, per_item])
		else:
			print("    %-10s cannot roll %s -> contributes 0" % [slot_names[slot], attribute_name])

	var unmodeled_slot_names: Array = []
	for slot in Types.Slot.values():
		if(not modeled_slots.has(slot)):
			unmodeled_slot_names.append(slot_names[slot])
	if(not unmodeled_slot_names.is_empty()):
		print("    (no attribute pool in code, excluded from the loadout: %s)"
				% ", ".join(unmodeled_slot_names))

	var geared_aggregate: float = CASTER_SCALED_BASE + float(gear_bonus)
	var modifier: float = geared_aggregate / CASTER_SCALED_BASE
	print("Gear bonus to %s: %d  (aggregate %.0f -> %.0f, %.3fx linear)"
			% [attribute_name, gear_bonus, CASTER_SCALED_BASE, geared_aggregate, modifier])
	for boss in BOSSES:
		var factors: Array[float] = [modifier]
		var ratio: float = ContrastRatioForFactors(factors, CASTER_SCALED_BASE, boss[2])
		print("    %-20s Defence %3.0f  contrast ratio %.3fx" % [boss[0], boss[2], ratio])
	print("")
