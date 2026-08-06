extends GutTest

## Coverage for Scripts/Debug/team_sweep.gd's DedupeByRole: the guard that keeps the
## Tests/manual/ sweeps from scoring duplicate-kit teams when the known roster lists more
## than one preset for the same Role (e.g. Centaur_Lancer.tres and Knight.tres both field
## Lancer).

const CENTAUR_LANCER = preload("res://Data/Character_Player_Variants/Centaur_Lancer.tres")
const KNIGHT = preload("res://Data/Character_Player_Variants/Knight.tres")
const TACTICIAN = preload("res://Data/Character_Player_Variants/Tactician.tres")


func test_keeps_only_the_first_preset_seen_per_role() -> void:
	var presets: Array[CharacterPreset] = [CENTAUR_LANCER, TACTICIAN, KNIGHT]
	var deduped: Array[CharacterPreset] = TeamSweep.DedupeByRole(presets)
	assert_eq(deduped, [CENTAUR_LANCER, TACTICIAN],
			"Knight.tres must be dropped: it fields the same Role as the already-seen Centaur_Lancer.tres")


func test_a_roster_with_no_shared_roles_passes_through_unchanged() -> void:
	var presets: Array[CharacterPreset] = [CENTAUR_LANCER, TACTICIAN]
	assert_eq(TeamSweep.DedupeByRole(presets), presets,
			"A roster with one preset per Role must be returned as-is")
