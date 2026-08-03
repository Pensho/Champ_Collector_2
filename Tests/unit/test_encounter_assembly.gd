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
}

## Enemy preset -> cataloged mechanic skill name(s) it must hold (Encounter Design
## Document section 1). Presets without a listed mechanic (e.g. pure Stab bodies, or
## Warded Clerk's plain high Resistance) are not asserted here.
const EXPECTED_SKILLS_BY_PRESET: Dictionary[String, Array] = {
	"res://Data/Character_Enemy_Variants/Sporeback_Matron.tres": ["Sporeburst Mend"],
	"res://Data/Character_Enemy_Variants/Bosun.tres": ["Rally the Crew"],
	"res://Data/Character_Enemy_Variants/War_Drummer.tres": ["March Cadence"],
	"res://Data/Character_Enemy_Variants/Ridge_Marksman.tres": ["Aimed Shot"],
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
}


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
