extends GutTest

## Not part of the default suite (Tests/unit/ only) — run explicitly:
##   /home/jonas/Documents/Godot_v4.7.1-stable_linux.x86_64 --headless -s addons/gut/gut_cmdln.gd
##   -gtest=res://Tests/manual/prescription_sweep.gd -gexit 2>&1 |   grep -vE '^(WARNING|ERROR):|^   at: '
##
## Quantifies candidate kit changes by re-running BurstReachability.ScoreTeam against a
## duplicated, modified copy of KitContributionManifest.MANIFEST (see
## BurstReachability.ScoreTeam's p_manifest parameter) — never by argument, and never by
## editing the real manifest. Same Character.new()-under-bare-`-s` constraint as
## team_corpus_sweep.gd, hence a GUT script rather than a SceneTree entry point.
##
## Four modeled changes, each reporting the full-roster median/90th-percentile/ceiling delta
## against the unmodified baseline, so a prescription that only lifts the ceiling (and not
## the median) is visible as such rather than assumed. A prescription that shows no aggregate
## movement is reported as such too — verified directly against a specific candidate, not
## dismissed as a bug: BurstReachability.TeamResult.Best() picks the highest COMBINED CONTRAST
## RATIO (single-action burst plus any repeat/sustained payload), not the highest product, so a
## small isolated factor can raise its own candidate's product while never becoming any team's
## actual burst resolution, or becoming one whose product still falls short of every reported
## statistic's threshold.

const AGGREGATE_TARGET: float = 26.0

## Matches Cataclysm's own bonus_per_debuff_on_target size
## (kit_contribution_manifest.gd's Sorcerer entry) — the one precedent for this hook shape
## already in the roster.
const STANDARD_HOOK_MAGNITUDE: float = 0.3

## Four Channel1-only damaging skills (kit_contribution_manifest.gd), one per role, that a
## bonus_per_debuff_on_target hook could be added to. Skill index is the position in that
## role's own "skills" array.
const HOOK_SKILL_INDEX_BY_ROLE: Dictionary = {
	Types.Role.Bar_Brawler: 1,  # Headbutt
	Types.Role.Symbiote: 0,  # Spore Lash
	Types.Role.Alchemist: 0,  # Acrid Splash
	Types.Role.Thief: 0,  # Stab
}

## The two Channel1/Enabler-only kits kit_contribution_manifest.gd's own entries flag as
## contributing no reachable bucket at all.
const ZERO_CONTRIBUTION_SKILL_INDEX: Dictionary = {
	Types.Role.Herald_Of_The_Loom: 0,  # Thread Snap
	Types.Role.Bloodmage: 0,  # Blood Bolt
}

## Plague_Doctor's own Miasma is already tagged Channel3_Cascade in the manifest, but its
## damage lands via the zone-triggered Plague status rather than a direct DamageEffect on
## Miasma itself — so it never satisfies BurstReachability._HasDamageEffect and can never
## become a scored candidate at all, verified below rather than assumed. Outbreak is
## Plague_Doctor's own direct-damage skill (Mysticism 1.2) instead, standing in as a real
## vehicle for the same repeating-factor shape a populated channel 3 would need. Magnitude is
## a per-instance rate, not a ceiling — multiplied by the modeled instance count.
const CASCADE_ROLE: Types.Role = Types.Role.Plague_Doctor
const CASCADE_SKILL_INDEX: int = 1  # Outbreak
const CASCADE_BASE_MAGNITUDE_PER_INSTANCE: float = 0.15
const CASCADE_INSTANCE_COUNTS: Array[int] = [1, 2, 4, 8, 16]  # 16 = CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION

## PRESET_PATHS is the full known roster, not hand-curated to one preset per Role: several
## presets can field the same Role (same trait, same three skills — e.g. Centaur_Lancer.tres
## and Knight.tres both field Lancer, per kit_contribution_manifest.gd's Lancer entry), and
## burst reachability is a property of the Role's kit, not of the preset fielding it. Listing
## every preset here and reducing through TeamSweep.DedupeByRole below, rather than curating
## the list by hand, means a future preset added to the roster that shares an existing Role is
## excluded from the sweep automatically instead of needing this list edited again.
const PRESET_PATHS: Array[String] = [
	"res://Data/Character_Player_Variants/Alchemist.tres",
	"res://Data/Character_Player_Variants/Appraiser.tres",
	"res://Data/Character_Player_Variants/Architect.tres",
	"res://Data/Character_Player_Variants/Bar_Brawler.tres",
	"res://Data/Character_Player_Variants/Bloodmage.tres",
	"res://Data/Character_Player_Variants/Centaur_Archivist.tres",
	"res://Data/Character_Player_Variants/Centaur_Lancer.tres",
	"res://Data/Character_Player_Variants/Chronophage.tres",
	"res://Data/Character_Player_Variants/Cultist.tres",
	"res://Data/Character_Player_Variants/Diviner.tres",
	"res://Data/Character_Player_Variants/Emissary.tres",
	"res://Data/Character_Player_Variants/Herald_of_the_loom.tres",
	"res://Data/Character_Player_Variants/Jester.tres",
	"res://Data/Character_Player_Variants/Knight.tres",
	"res://Data/Character_Player_Variants/Plague_Doctor.tres",
	"res://Data/Character_Player_Variants/Sorcerer.tres",
	"res://Data/Character_Player_Variants/Symbiote.tres",
	"res://Data/Character_Player_Variants/Tactician.tres",
	"res://Data/Character_Player_Variants/Thief.tres",
	"res://Data/Character_Player_Variants/Tidal_Corsair.tres",
	"res://Data/Character_Player_Variants/Warlord.tres",
]

var _presets: Array[CharacterPreset] = []
var _baseline_products: Array[float] = []
var _baseline_stats: Dictionary = {}


## Types.Role.keys()[value] is WRONG here: GDScript enums are Dictionaries, and Role skips
## value 1 and runs to Warlord=21 over 21 declaration slots (common_enums.gd) — keys() is
## ordered by declaration, not by value, so indexing it by value misnames every member past
## Emissary and is out of range for Warlord. find_key(value) returns the correct name directly.
func _RoleName(p_role: Types.Role) -> String:
	return Types.Role.find_key(p_role)


func before_all() -> void:
	for path in PRESET_PATHS:
		_presets.append(load(path))
	_presets = TeamSweep.DedupeByRole(_presets)
	_baseline_products = _ProductsUnder(KitContributionManifest.MANIFEST)
	_baseline_stats = _Stats(_baseline_products)


func _Stats(p_products: Array[float]) -> Dictionary:
	var sorted: Array[float] = p_products.duplicate()
	sorted.sort()
	return {
		"median": TeamSweep.Percentile(sorted, 0.5),
		"ninetieth": TeamSweep.Percentile(sorted, 0.9),
		"max": sorted[sorted.size() - 1],
	}


func _ProductsUnder(p_manifest: Dictionary) -> Array[float]:
	var rows: Array[Dictionary] = TeamSweep.ScoreAllTeams(_presets, p_manifest)
	var products: Array[float] = []
	for row: Dictionary in rows:
		products.append(row["product"])
	return products


func _PrintStatsRow(p_label: String, p_stats: Dictionary) -> void:
	gut.p("%-28s median=%.2fx (%+.2f) 90th=%.2fx (%+.2f) max=%.2fx (%+.2f)"
			% [p_label, p_stats["median"], p_stats["median"] - _baseline_stats["median"],
			p_stats["ninetieth"], p_stats["ninetieth"] - _baseline_stats["ninetieth"],
			p_stats["max"], p_stats["max"] - _baseline_stats["max"]])


# --- Prescription: spread a bonus_per_debuff_on_target hook across N Channel1-only skills ---

func test_prescription_spread_debuff_anchored_hooks() -> void:
	gut.p(("=== Prescription: spread a bonus_per_debuff_on_target hook (%.2f, matching " +
			"Cataclysm) across N Channel1-only skills ===") % STANDARD_HOOK_MAGNITUDE)
	_PrintStatsRow("N=0 (current roster)", _baseline_stats)
	var roles: Array = HOOK_SKILL_INDEX_BY_ROLE.keys()
	var last_stats: Dictionary = _baseline_stats
	for n in range(1, roles.size() + 1):
		var manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
		for i in n:
			var role: Types.Role = roles[i]
			var skill_entry: Dictionary = manifest[role]["skills"][HOOK_SKILL_INDEX_BY_ROLE[role]]
			skill_entry["bucket_key"] = "Prescribed Hook: %s" % _RoleName(role)
			skill_entry["magnitude"] = STANDARD_HOOK_MAGNITUDE
			skill_entry["class"] = KitContributionManifest.Contribution_Class.Channel2
		last_stats = _Stats(_ProductsUnder(manifest))
		_PrintStatsRow("N=%d hooks" % n, last_stats)

	# The mechanism itself does reach the scorer — verified directly on the one team it
	# composes best on (Bar_Brawler's Headbutt plus Tactician's unconditionally granted
	# Daunting_Strength) — but (1+0.3)*(1+1.0)=2.6x never crosses the roster's 90th-percentile
	# threshold (2.80x), so the aggregate stats above correctly stay flat at every N.
	var one_hook_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var bar_brawler_entry: Dictionary = one_hook_manifest[Types.Role.Bar_Brawler]["skills"][1]
	bar_brawler_entry["bucket_key"] = "Prescribed Hook: Bar_Brawler"
	bar_brawler_entry["magnitude"] = STANDARD_HOOK_MAGNITUDE
	bar_brawler_entry["class"] = KitContributionManifest.Contribution_Class.Channel2
	var team: Array[CharacterPreset] = [
		load("res://Data/Character_Player_Variants/Bar_Brawler.tres"),
		load("res://Data/Character_Player_Variants/Tactician.tres"),
		load("res://Data/Character_Player_Variants/Chronophage.tres"),
	]
	var without_hook: float = BurstReachability.ScoreTeam(team).Pinned(0, "Headbutt").product
	var with_hook: float = BurstReachability.ScoreTeam(team, 0, one_hook_manifest).Pinned(0, "Headbutt").product
	assert_gt(with_hook, without_hook,
			"The hook must reach the scorer for the one team it composes best on")
	assert_almost_eq(last_stats["max"], _baseline_stats["max"], 0.0001,
			"An isolated 0.3 hook tops out at 2.6x composed with Daunting_Strength, short of " +
			"the 90th-percentile threshold, so the ceiling itself must stay flat at every N")


# --- Prescription: retune every existing Channel2/Channel3 magnitude uniformly ---

func _ProductsUnderUniformRetune(p_multiplier: float) -> Array[float]:
	var manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	for role: Types.Role in manifest.keys():
		var entry: Dictionary = manifest[role]
		for group in ["passive", "skills"]:
			for skill_entry: Dictionary in entry.get(group, []):
				if(KitContributionManifest.Contribution_Class.Channel2 == skill_entry.get("class") \
						or KitContributionManifest.Contribution_Class.Channel3_Cascade == skill_entry.get("class")):
					skill_entry["magnitude"] = skill_entry.get("magnitude", 0.0) * p_multiplier
				# An Enabler-classed entry (e.g. Tactician's Fatal Flaw) can still carry a
				# granted_status whose magnitude lands as a real Channel-2 factor on whichever
				# teammate consumes the grant — a uniform Channel-2/3 retune must scale that
				# too, or a factor like Daunting Strength silently sits out the retune.
				if(skill_entry.has("granted_status")):
					var grant: Dictionary = skill_entry["granted_status"]
					grant["magnitude"] = grant.get("magnitude", 0.0) * p_multiplier
	return _ProductsUnder(manifest)


func test_prescription_retune_existing_channel_two_magnitudes() -> void:
	gut.p("=== Prescription: retune every existing Channel2/Channel3 magnitude uniformly ===")

	# A modest, plausible single balance patch first, for comparison against the other
	# prescriptions' single-unit cost.
	var modest_stats: Dictionary = _Stats(_ProductsUnderUniformRetune(1.25))
	_PrintStatsRow("1.25x retune (modest patch)", modest_stats)

	# Then solve, through the real scorer via bisection (not by argument), the uniform
	# multiplier needed to reach 1.1's aggregate target.
	var low: float = 1.0
	var high: float = 8.0
	var high_stats: Dictionary = _Stats(_ProductsUnderUniformRetune(high))
	assert_gte(high_stats["max"], AGGREGATE_TARGET,
			"The search bracket's upper bound must already reach the target; otherwise raise it")
	for _iteration in 20:
		var middle: float = (low + high) * 0.5
		var stats: Dictionary = _Stats(_ProductsUnderUniformRetune(middle))
		if(stats["max"] < AGGREGATE_TARGET):
			low = middle
		else:
			high = middle
	var required_multiplier: float = high
	var final_stats: Dictionary = _Stats(_ProductsUnderUniformRetune(required_multiplier))
	gut.p("Required multiplier on the current factor set to reach %.0fx: %.2fx"
			% [AGGREGATE_TARGET, required_multiplier])
	_PrintStatsRow("At %.2fx (reaches target)" % required_multiplier, final_stats)
	assert_gte(final_stats["max"], AGGREGATE_TARGET - 0.01,
			"The solved multiplier must actually reach the target product")


# --- Prescription: add one distinct Channel2 key to each zero-contribution kit ---

func test_prescription_add_a_distinct_key_to_each_zero_contribution_kit() -> void:
	gut.p(("=== Prescription: add one Channel2 factor (%.2f) to each zero-contribution kit " +
			"(Herald of the Loom, Bloodmage) ===") % STANDARD_HOOK_MAGNITUDE)

	# One kit at a time first, for a single-unit-of-work comparison against the other
	# prescriptions.
	for role: Types.Role in ZERO_CONTRIBUTION_SKILL_INDEX.keys():
		var manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
		var skill_entry: Dictionary = manifest[role]["skills"][ZERO_CONTRIBUTION_SKILL_INDEX[role]]
		skill_entry["bucket_key"] = "Prescribed Factor: %s" % _RoleName(role)
		skill_entry["magnitude"] = STANDARD_HOOK_MAGNITUDE
		skill_entry["class"] = KitContributionManifest.Contribution_Class.Channel2
		_PrintStatsRow("%s alone" % _RoleName(role), _Stats(_ProductsUnder(manifest)))

	# Both zero-contribution kits together — a distinct Channel-2 key on each, at once.
	var both_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	for role: Types.Role in ZERO_CONTRIBUTION_SKILL_INDEX.keys():
		var skill_entry: Dictionary = both_manifest[role]["skills"][ZERO_CONTRIBUTION_SKILL_INDEX[role]]
		skill_entry["bucket_key"] = "Prescribed Factor: %s" % _RoleName(role)
		skill_entry["magnitude"] = STANDARD_HOOK_MAGNITUDE
		skill_entry["class"] = KitContributionManifest.Contribution_Class.Channel2
	var both_stats: Dictionary = _Stats(_ProductsUnder(both_manifest))
	_PrintStatsRow("Both kits", both_stats)

	# Same reasoning as the spread-hook prescription: verified directly on Bloodmage's own
	# resolution, but a lone 0.3 factor again tops out at 2.6x composed with
	# Daunting_Strength — short of the 90th-percentile threshold, so the ceiling stays flat.
	var solo_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var bloodmage_entry: Dictionary = solo_manifest[Types.Role.Bloodmage]["skills"][0]
	bloodmage_entry["bucket_key"] = "Prescribed Factor: Bloodmage"
	bloodmage_entry["magnitude"] = STANDARD_HOOK_MAGNITUDE
	bloodmage_entry["class"] = KitContributionManifest.Contribution_Class.Channel2
	var team: Array[CharacterPreset] = [
		load("res://Data/Character_Player_Variants/Bloodmage.tres"),
		load("res://Data/Character_Player_Variants/Tactician.tres"),
		load("res://Data/Character_Player_Variants/Chronophage.tres"),
	]
	var without_factor: float = BurstReachability.ScoreTeam(team).Pinned(0, "Blood Bolt").product
	var with_factor: float = BurstReachability.ScoreTeam(team, 0, solo_manifest).Pinned(0, "Blood Bolt").product
	assert_gt(with_factor, without_factor,
			"The new factor must reach the scorer for Bloodmage's own resolution")
	assert_almost_eq(both_stats["max"], _baseline_stats["max"], 0.0001,
			"Same ceiling as the spread-hook prescription: a lone 0.3 factor tops out at 2.6x")


# --- Prescription: populate channel 3 via CascadeEvent.instance_count ---

func test_prescription_populate_channel_three_via_cascade_instance_count() -> void:
	gut.p(("=== Prescription: populate channel 3 — give a direct-damage skill a repeating " +
			"Channel3_Cascade factor (%.2f/instance), modeling CascadeEvent.instance_count ===")
			% CASCADE_BASE_MAGNITUDE_PER_INSTANCE)

	# Miasma itself cannot carry this model: its damage lands via the zone-triggered Plague
	# status, never a direct DamageEffect on Miasma itself, so BurstReachability's own
	# candidate enumeration (_HasDamageEffect) excludes it — verified directly, not assumed.
	var miasma_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var miasma_entry: Dictionary = miasma_manifest[Types.Role.Plague_Doctor]["skills"][2]
	miasma_entry["bucket_key"] = "Miasma Spread"
	miasma_entry["magnitude"] = 999.0
	var miasma_team: Array[CharacterPreset] = [
		load("res://Data/Character_Player_Variants/Plague_Doctor.tres"),
		load("res://Data/Character_Player_Variants/Tactician.tres"),
		load("res://Data/Character_Player_Variants/Chronophage.tres"),
	]
	var miasma_result: BurstReachability.TeamResult = (
			BurstReachability.ScoreTeam(miasma_team, 0, miasma_manifest))
	assert_null(miasma_result.Pinned(0, "Miasma"),
			"Miasma must never be a scored candidate under the current scorer, regardless of " +
			"the magnitude given to it — its damage is zone/status-triggered, not direct")

	gut.p("(Outbreak — Plague_Doctor's own direct-damage skill — stands in instead.)")
	_PrintStatsRow("K=0 (current, inert)", _baseline_stats)
	var stats_by_k: Dictionary = {}
	for instances in CASCADE_INSTANCE_COUNTS:
		var manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
		var skill_entry: Dictionary = manifest[CASCADE_ROLE]["skills"][CASCADE_SKILL_INDEX]
		skill_entry["bucket_key"] = "Plague Spread"
		skill_entry["magnitude"] = CASCADE_BASE_MAGNITUDE_PER_INSTANCE * float(instances)
		skill_entry["class"] = KitContributionManifest.Contribution_Class.Channel3_Cascade
		var stats: Dictionary = _Stats(_ProductsUnder(manifest))
		_PrintStatsRow("K=%d instances" % instances, stats)
		stats_by_k[instances] = stats

	assert_lte(CASCADE_INSTANCE_COUNTS[CASCADE_INSTANCE_COUNTS.size() - 1],
			CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION,
			"The modeled instance count must never exceed the real per-action cascade cap")
	assert_almost_eq(stats_by_k[1]["max"], _baseline_stats["max"], 0.0001,
			"One instance (0.15) composes to only 2.3x with Daunting_Strength, below the ceiling")
	assert_gt(stats_by_k[16]["max"], _baseline_stats["max"],
			"16 instances (the per-action cap) must raise the ceiling once a direct-damage " +
			"skill carries a real repeating Channel3 factor")


# --- Ranking: one comparable "single unit of work" ceiling delta per prescription ---

## "Unit of work" is a stated ordinal judgment, not a formula this codebase can derive: one
## hook wired to one skill, one balance-only magnitude patch, one new factor on one kit, and
## one authored repeating-cascade effect (its own instance count is a battle outcome, not
## added dev cost, so K=16 — the architectural cap — stands in for "the content exists and
## fires as often as a battle allows").
func test_prescription_ranking_by_ceiling_delta_per_single_unit_of_work() -> void:
	var one_hook_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var hook_role: Types.Role = HOOK_SKILL_INDEX_BY_ROLE.keys()[0]
	var hook_entry: Dictionary = one_hook_manifest[hook_role]["skills"][HOOK_SKILL_INDEX_BY_ROLE[hook_role]]
	hook_entry["bucket_key"] = "Prescribed Hook: %s" % _RoleName(hook_role)
	hook_entry["magnitude"] = STANDARD_HOOK_MAGNITUDE
	hook_entry["class"] = KitContributionManifest.Contribution_Class.Channel2
	var spread_hook_delta: float = _Stats(_ProductsUnder(one_hook_manifest))["max"] - _baseline_stats["max"]

	var retune_delta: float = _Stats(_ProductsUnderUniformRetune(1.25))["max"] - _baseline_stats["max"]

	var zero_contribution_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var zero_role: Types.Role = ZERO_CONTRIBUTION_SKILL_INDEX.keys()[0]
	var zero_entry: Dictionary = (
			zero_contribution_manifest[zero_role]["skills"][ZERO_CONTRIBUTION_SKILL_INDEX[zero_role]])
	zero_entry["bucket_key"] = "Prescribed Factor: %s" % _RoleName(zero_role)
	zero_entry["magnitude"] = STANDARD_HOOK_MAGNITUDE
	zero_entry["class"] = KitContributionManifest.Contribution_Class.Channel2
	var zero_contribution_delta: float = (
			_Stats(_ProductsUnder(zero_contribution_manifest))["max"] - _baseline_stats["max"])

	var cascade_manifest: Dictionary = KitContributionManifest.MANIFEST.duplicate(true)
	var cascade_entry: Dictionary = cascade_manifest[CASCADE_ROLE]["skills"][CASCADE_SKILL_INDEX]
	cascade_entry["bucket_key"] = "Plague Spread"
	cascade_entry["magnitude"] = CASCADE_BASE_MAGNITUDE_PER_INSTANCE * 16.0
	cascade_entry["class"] = KitContributionManifest.Contribution_Class.Channel3_Cascade
	var cascade_delta: float = _Stats(_ProductsUnder(cascade_manifest))["max"] - _baseline_stats["max"]

	var ranking: Array[Dictionary] = [
		{"name": "Spread a debuff-anchored hook (1 skill)", "delta": spread_hook_delta,
				"grows_distinct_keys": true},
		{"name": "Retune existing Channel2/3 magnitudes (1.25x)", "delta": retune_delta,
				"grows_distinct_keys": false},
		{"name": "Add a distinct key to one zero-contribution kit", "delta": zero_contribution_delta,
				"grows_distinct_keys": true},
		{"name": "Populate channel 3 (1 repeating factor, K=16)", "delta": cascade_delta,
				"grows_distinct_keys": true},
	]
	ranking.sort_custom(func(a, b): return a["delta"] > b["delta"])

	gut.p("=== Ranking: ceiling delta per single unit of work ===")
	for entry: Dictionary in ranking:
		gut.p("%-48s ceiling %+.2fx  %s" % [entry["name"], entry["delta"],
				"grows distinct-key count" if entry["grows_distinct_keys"] else "magnitude only"])

	for i in ranking.size() - 1:
		assert_gte(ranking[i]["delta"], ranking[i + 1]["delta"],
				"Ranking must be sorted by ceiling delta, largest first")
