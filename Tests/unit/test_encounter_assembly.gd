extends GutTest

## Rules every encounter must satisfy: a battle fields 1-3 bodies, and a boss placed in an
## adventure has a phase 2.

const BATTLE_VARIANTS_DIRECTORY: String = "res://Data/Battle_Variants/"

const ADVENTURES_DIRECTORY: String = "res://Data/Adventure_Data/Adventures/"

## Adventures whose boss is a placeholder awaiting its own encounter design, so it has no
## phase 2 yet.
const PLACEHOLDER_BOSS_ADVENTURES: Array[String] = [
	"res://Data/Adventure_Data/Adventures/adventure_reclaimed_city_magic_ruins.tres",
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
