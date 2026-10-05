extends GutTest

## Wiring test for encounter assembly: every battle definition fields a 1-3 body
## composition (the design rule for fodder/mini-boss/boss waves), and every enemy
## carrying a cataloged mechanic actually holds that skill. Logic/wiring only -- no
## description-wording or icon assertions.

const BATTLE_VARIANTS_DIRECTORY: String = "res://Data/Battle_Variants/"

## Battle -> expected enemy composition, by preset resource path.
const EXPECTED_COMPOSITIONS: Dictionary[String, Array] = {
	"res://Data/Battle_Variants/Battle_Sporeback_Pack.tres": [
		"res://Data/Character_Enemy_Variants/Spore_Hound.tres",
		"res://Data/Character_Enemy_Variants/Spore_Hound.tres",
		"res://Data/Character_Enemy_Variants/Sporeback_Matron.tres",
	],
	"res://Data/Battle_Variants/Battle_Wake_Skimmers.tres": [
		"res://Data/Character_Enemy_Variants/Skimmer_Cutthroat.tres",
		"res://Data/Character_Enemy_Variants/Skimmer_Cutthroat.tres",
		"res://Data/Character_Enemy_Variants/Bosun.tres",
	],
	"res://Data/Battle_Variants/Battle_Ledger_Clerks.tres": [
		"res://Data/Character_Enemy_Variants/Warded_Clerk.tres",
		"res://Data/Character_Enemy_Variants/Warded_Clerk.tres",
		"res://Data/Character_Enemy_Variants/Warded_Clerk.tres",
	],
	"res://Data/Battle_Variants/Battle_Plains_Outriders.tres": [
		"res://Data/Character_Enemy_Variants/Outrider_Lancer.tres",
		"res://Data/Character_Enemy_Variants/Outrider_Lancer.tres",
		"res://Data/Character_Enemy_Variants/War_Drummer.tres",
	],
	"res://Data/Battle_Variants/Battle_Ridge_Marksmen.tres": [
		"res://Data/Character_Enemy_Variants/Scavenger_Skirmisher.tres",
		"res://Data/Character_Enemy_Variants/Scavenger_Skirmisher.tres",
		"res://Data/Character_Enemy_Variants/Ridge_Marksman.tres",
	],
	"res://Data/Battle_Variants/Battle_Flank_Cutter.tres": [
		"res://Data/Character_Enemy_Variants/Flank_Cutter.tres",
	],
	"res://Data/Battle_Variants/Battle_Line_Breaker.tres": [
		"res://Data/Character_Enemy_Variants/Plains_Charger.tres",
		"res://Data/Character_Enemy_Variants/Drover.tres",
	],
	"res://Data/Battle_Variants/Battle_Ashen_Oracle.tres": [
		"res://Data/Character_Enemy_Variants/Ashen_Oracle.tres",
		"res://Data/Character_Enemy_Variants/Cinder_Husk.tres",
		"res://Data/Character_Enemy_Variants/Cinder_Husk.tres",
	],
	"res://Data/Battle_Variants/Battle_Glyphbound_Archivist.tres": [
		"res://Data/Character_Enemy_Variants/Glyphbound_Archivist.tres",
	],
	"res://Data/Battle_Variants/Battle_Collector_of_Debts.tres": [
		"res://Data/Character_Enemy_Variants/Collector_of_Debts.tres",
		"res://Data/Character_Enemy_Variants/Warded_Notary.tres",
	],
	"res://Data/Battle_Variants/Battle_Warden_of_the_Reliquary.tres": [
		"res://Data/Character_Enemy_Variants/Vault_Warden.tres",
		"res://Data/Character_Enemy_Variants/Reliquary_Core.tres",
	],
	"res://Data/Battle_Variants/Battle_Statue_Boots.tres": [
		"res://Data/Character_Enemy_Variants/Statue_Boots.tres",
	],
	"res://Data/Battle_Variants/Battle_Clearing_Crew.tres": [
		"res://Data/Character_Enemy_Variants/Rubble_Breaker.tres",
		"res://Data/Character_Enemy_Variants/Vinecutter.tres",
	],
	"res://Data/Battle_Variants/Battle_Salvage_Baron.tres": [
		"res://Data/Character_Enemy_Variants/Scavenger_Skirmisher.tres",
		"res://Data/Character_Enemy_Variants/Salvage_Baron.tres",
		"res://Data/Character_Enemy_Variants/Scavenger_Skirmisher.tres",
	],
}

## Enemy preset -> cataloged mechanic skill name(s) it must hold (Encounter Design
## Document section 1). Presets without a listed mechanic (e.g. pure Stab bodies, or
## Warded Clerk's plain high Resistance) are not asserted here.
const EXPECTED_SKILLS_BY_PRESET: Dictionary[String, Array] = {
	"res://Data/Character_Enemy_Variants/Sporeback_Matron.tres": ["Sporeburst Mend"],
	"res://Data/Character_Enemy_Variants/Bosun.tres": ["Rally the Crew"],
	"res://Data/Character_Enemy_Variants/War_Drummer.tres": ["March Cadence"],
	"res://Data/Character_Enemy_Variants/Ridge_Marksman.tres": ["Spotting Shot", "Aimed Shot"],
	"res://Data/Character_Enemy_Variants/Flank_Cutter.tres": ["Flank Cut"],
	"res://Data/Character_Enemy_Variants/Plains_Charger.tres": ["Breaching Charge"],
	"res://Data/Character_Enemy_Variants/Ashen_Oracle.tres": ["Cinder Spit", "Cinder Sermon"],
	"res://Data/Character_Enemy_Variants/Glyphbound_Archivist.tres": ["Inscribe", "Inscription Surge"],
	"res://Data/Character_Enemy_Variants/Collector_of_Debts.tres": ["Foreclosure"],
	"res://Data/Character_Enemy_Variants/Warded_Notary.tres": ["Writ of Seizure"],
	"res://Data/Character_Enemy_Variants/Vault_Warden.tres": ["Vault Slam"],
	"res://Data/Character_Enemy_Variants/Reliquary_Core.tres": ["Reliquary Ward"],
	"res://Data/Character_Enemy_Variants/Statue_Boots.tres": ["Wind the Mainspring"],
	"res://Data/Character_Enemy_Variants/Statue_Weapon.tres": ["Break Guard", "Crush"],
	"res://Data/Character_Enemy_Variants/Rubble_Breaker.tres": ["Breaching Charge"],
	"res://Data/Character_Enemy_Variants/Vinecutter.tres": ["Flank Cut"],
	"res://Data/Character_Enemy_Variants/Salvage_Baron.tres": ["Size Up", "Cash In"],
}

const ADVENTURES_DIRECTORY: String = "res://Data/Adventure_Data/Adventures/"

## Adventures whose boss is a placeholder awaiting its own encounter design, so it has no
## phase 2 yet.
const PLACEHOLDER_BOSS_ADVENTURES: Array[String] = [
	"res://Data/Adventure_Data/Adventures/adventure_reclaimed_city_magic_ruins.tres",
]

const SPOTTING_SKILLS: Array[String] = [
	"res://Data/Character_Skill_Variants/Attack_Skills/Spotting_Shot.tres",
	"res://Data/Character_Skill_Variants/Attack_Skills/Size_Up.tres",
]


func test_every_battle_variant_fields_one_to_three_enemies() -> void:
	var dir := DirAccess.open(BATTLE_VARIANTS_DIRECTORY)
	assert_not_null(dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var battle: Context_Battle = load(BATTLE_VARIANTS_DIRECTORY.path_join(file_name))
			var count: int = battle._enemies_wave_1.size()
			assert_true(count >= 1 and count <= 3,
					"%s: composition size %d outside the 1-3 design rule" % [file_name, count])
		file_name = dir.get_next()


func test_expected_compositions_match_the_battle_definitions() -> void:
	for battle_path in EXPECTED_COMPOSITIONS:
		var battle: Context_Battle = load(battle_path)
		var expected_paths: Array = EXPECTED_COMPOSITIONS[battle_path]
		var actual_paths: Array = []
		for preset: CharacterPreset in battle._enemies_wave_1:
			actual_paths.append(preset.resource_path)
		assert_eq(actual_paths, expected_paths, "%s: composition mismatch" % battle_path)


func test_enemies_carrying_a_cataloged_mechanic_hold_that_skill() -> void:
	for preset_path in EXPECTED_SKILLS_BY_PRESET:
		var preset: CharacterPreset = load(preset_path)
		var held_skill_names: Array = []
		for skill: Skill in preset._skills:
			held_skill_names.append(skill.name)
		for expected_skill_name in EXPECTED_SKILLS_BY_PRESET[preset_path]:
			assert_true(held_skill_names.has(expected_skill_name),
					"%s: missing expected skill %s (has %s)" %
							[preset_path, expected_skill_name, held_skill_names])


func test_spotting_skills_damage_the_chosen_enemy_and_spot_the_lowest_priority_one() -> void:
	for skill_path in SPOTTING_SKILLS:
		var skill: Skill = load(skill_path)
		assert_eq(skill.target, Types.Skill_Target.Single_Enemy, "%s: damages a chosen enemy" % skill_path)
		var spotted_effects: Array = skill.effects.filter(
				func(effect: SkillEffect) -> bool:
					return effect is ApplyDebuffEffect and Types.Debuff_Type.Spotted == effect.debuff_type)
		assert_eq(spotted_effects.size(), 1, "%s: carries one Spotted application" % skill_path)
		if(spotted_effects.size() == 1):
			assert_eq(spotted_effects[0].target, Types.Skill_Target.Lowest_Priority_Enemy)
			assert_eq(spotted_effects[0].duration, 2)


func test_aimed_shot_follows_the_chosen_target() -> void:
	var aimed_shot: Skill = load("res://Data/Character_Skill_Variants/Attack_Skills/Aimed_Shot.tres")
	assert_eq(aimed_shot.target, Types.Skill_Target.Single_Enemy,
			"Aimed Shot must take the chosen target so it follows Spotted")


func test_salvage_baron_gains_press_the_advantage_in_phase_two() -> void:
	var baron: CharacterPreset = load("res://Data/Character_Enemy_Variants/Salvage_Baron.tres")
	assert_true(baron._phase_two_trait is PressTheAdvantageTrait)


func test_every_placed_boss_has_a_phase_two() -> void:
	var dir := DirAccess.open(ADVENTURES_DIRECTORY)
	assert_not_null(dir)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var adventure_path: String = ADVENTURES_DIRECTORY.path_join(file_name)
		if PLACEHOLDER_BOSS_ADVENTURES.has(adventure_path):
			continue
		var adventure: AdventureData = load(adventure_path)
		for boss_battle: Context_Battle in adventure.boss_battle_variants:
			var phased: bool = boss_battle._enemies_wave_1.any(
					func(preset: CharacterPreset) -> bool:
						return not preset._phase_two_skills.is_empty() or null != preset._phase_two_trait)
			assert_true(phased, "%s: boss battle %s has no phase 2 boss" % [file_name, boss_battle.resource_path])


func test_ridge_marksmans_spotting_shot_spots_the_lowest_priority_champion() -> void:
	var TestFactory = load("res://Tests/unit/helpers/test_factory.gd")
	var roster: Dictionary[int, Character] = {}
	roster.assign(TestFactory.make_full_roster())
	roster[2]._attributes[Types.Attribute.Defence] = 1
	var marksman: Character = Character.new()
	marksman.InstantiateNew(load("res://Data/Character_Enemy_Variants/Ridge_Marksman.tres"), 3)
	marksman._current_health = 1000
	roster[3] = marksman
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	resolver.ResolveSkill(3, [0], 0)
	var spotted: bool = roster[2]._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Spotted == debuff.type)
	assert_true(spotted, "Spotting Shot should Spot the lowest-priority champion, not the one it hit")
