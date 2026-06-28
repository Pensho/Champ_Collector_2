extends SceneTree

## Data-driven generator for flat-color placeholder background textures.
##
## Each row in `element_table` describes one checklist element. For every variant
## a single-color (optionally semi-transparent) PNG is written to
## `Assets/Adventure/Background/<folder>/<base_name>_NN.png`. Variants are nudged
## in value/alpha so they are visibly distinguishable.
##
## Existing files are skipped so hand-replaced real art is never clobbered; set
## `OVERWRITE` to true to force regeneration.
##
## Run headless:
##   godot --headless -s res://Scripts/Debug/generate_placeholder_textures.gd

const OVERWRITE: bool = false
const BACKGROUND_ROOT: String = "res://Assets/Adventure/Background"

# One row per checklist element.
#   folder, base_name, width, height, variants, color
const ELEMENT_TABLE: Array = [
	# --- Tier 1: Shared generics ---
	{ "folder": "Shared", "base_name": "grass_tuft_short", "width": 32, "height": 32, "variants": 3, "color": Color(0.30, 0.65, 0.25, 1.0) },
	{ "folder": "Shared", "base_name": "grass_tuft_tall", "width": 48, "height": 64, "variants": 2, "color": Color(0.18, 0.45, 0.16, 1.0) },
	{ "folder": "Shared", "base_name": "pebble_cluster", "width": 48, "height": 32, "variants": 3, "color": Color(0.55, 0.55, 0.55, 1.0) },
	{ "folder": "Shared", "base_name": "large_boulder", "width": 128, "height": 96, "variants": 2, "color": Color(0.35, 0.35, 0.35, 1.0) },
	{ "folder": "Shared", "base_name": "dead_tree_stump", "width": 64, "height": 96, "variants": 2, "color": Color(0.45, 0.30, 0.18, 1.0) },
	{ "folder": "Shared", "base_name": "bush_shrub", "width": 80, "height": 80, "variants": 2, "color": Color(0.28, 0.55, 0.28, 1.0) },
	{ "folder": "Shared", "base_name": "dirt_scree_patch", "width": 128, "height": 96, "variants": 3, "color": Color(0.50, 0.36, 0.22, 0.6) },
	{ "folder": "Shared", "base_name": "water_puddle", "width": 96, "height": 64, "variants": 2, "color": Color(0.30, 0.50, 0.75, 0.5) },
	{ "folder": "Shared", "base_name": "fog_mist_patch", "width": 256, "height": 160, "variants": 2, "color": Color(1.0, 1.0, 1.0, 0.3) },
	{ "folder": "Shared", "base_name": "flower_speck", "width": 24, "height": 24, "variants": 3, "color": Color(0.95, 0.40, 0.65, 1.0) },

	# --- Tier 2: Node props (biome-agnostic, distinct solid colors) ---
	{ "folder": "Shared", "base_name": "node_prop_fight", "width": 56, "height": 56, "variants": 1, "color": Color(0.80, 0.20, 0.20, 1.0) },
	{ "folder": "Shared", "base_name": "node_prop_boss", "width": 56, "height": 56, "variants": 1, "color": Color(0.55, 0.10, 0.10, 1.0) },
	{ "folder": "Shared", "base_name": "node_prop_rest_stop", "width": 56, "height": 56, "variants": 1, "color": Color(0.20, 0.70, 0.40, 1.0) },
	{ "folder": "Shared", "base_name": "node_prop_hint", "width": 56, "height": 56, "variants": 1, "color": Color(0.25, 0.55, 0.85, 1.0) },
	{ "folder": "Shared", "base_name": "node_prop_gamble", "width": 56, "height": 56, "variants": 1, "color": Color(0.85, 0.65, 0.15, 1.0) },
	{ "folder": "Shared", "base_name": "node_prop_escalate", "width": 56, "height": 56, "variants": 1, "color": Color(0.70, 0.30, 0.80, 1.0) },

	# --- Tier 3: reclaimed_city ---
	{ "folder": "reclaimed_city", "base_name": "broadleaf_tree", "width": 160, "height": 384, "variants": 3, "color": Color(0.22, 0.55, 0.22, 1.0) },
	{ "folder": "reclaimed_city", "base_name": "ruined_wall_fragment", "width": 128, "height": 128, "variants": 3, "color": Color(0.52, 0.52, 0.52, 1.0) },
	{ "folder": "reclaimed_city", "base_name": "logic_moss_patch", "width": 96, "height": 48, "variants": 1, "color": Color(0.30, 0.60, 0.30, 0.6) },
	{ "folder": "reclaimed_city", "base_name": "vine_draped_rubble", "width": 128, "height": 128, "variants": 1, "color": Color(0.40, 0.50, 0.38, 1.0) },
	{ "folder": "reclaimed_city", "base_name": "toxic_spore_mushroom", "width": 48, "height": 48, "variants": 1, "color": Color(0.60, 0.30, 0.70, 1.0) },
	{ "folder": "reclaimed_city", "base_name": "fallen_log_01", "width": 160, "height": 64, "variants": 1, "color": Color(0.45, 0.30, 0.18, 1.0) },

	# --- Tier 3: pirate_coves ---
	{ "folder": "pirate_coves", "base_name": "sand_dune", "width": 128, "height": 96, "variants": 2, "color": Color(0.85, 0.75, 0.50, 0.7) },
	{ "folder": "pirate_coves", "base_name": "palm_tree", "width": 160, "height": 192, "variants": 1, "color": Color(0.25, 0.58, 0.28, 1.0) },
	{ "folder": "pirate_coves", "base_name": "driftwood_debris", "width": 128, "height": 64, "variants": 1, "color": Color(0.62, 0.55, 0.45, 1.0) },
	{ "folder": "pirate_coves", "base_name": "tide_pool", "width": 96, "height": 64, "variants": 1, "color": Color(0.30, 0.50, 0.75, 0.5) },
	{ "folder": "pirate_coves", "base_name": "beached_barrel", "width": 64, "height": 80, "variants": 1, "color": Color(0.45, 0.30, 0.18, 1.0) },
	{ "folder": "pirate_coves", "base_name": "jagged_sea_rock", "width": 128, "height": 96, "variants": 1, "color": Color(0.32, 0.32, 0.35, 1.0) },

	# --- Tier 3: clockwork_spire ---
	{ "folder": "clockwork_spire", "base_name": "sand_dune", "width": 128, "height": 96, "variants": 1, "color": Color(0.85, 0.75, 0.50, 0.7) },
	{ "folder": "clockwork_spire", "base_name": "broken_gear", "width": 80, "height": 80, "variants": 1, "color": Color(0.70, 0.50, 0.25, 1.0) },
	{ "folder": "clockwork_spire", "base_name": "scrap_metal_debris", "width": 96, "height": 64, "variants": 1, "color": Color(0.55, 0.55, 0.55, 1.0) },
	{ "folder": "clockwork_spire", "base_name": "soot_glass_deposit", "width": 48, "height": 48, "variants": 1, "color": Color(0.22, 0.24, 0.28, 0.8) },
	{ "folder": "clockwork_spire", "base_name": "dead_cactus", "width": 64, "height": 96, "variants": 1, "color": Color(0.45, 0.50, 0.25, 1.0) },
	{ "folder": "clockwork_spire", "base_name": "steam_vent", "width": 96, "height": 128, "variants": 1, "color": Color(1.0, 1.0, 1.0, 0.3) },

	# --- Tier 3: holy_city_plains ---
	{ "folder": "holy_city_plains", "base_name": "grass_field", "width": 64, "height": 48, "variants": 1, "color": Color(0.30, 0.62, 0.28, 1.0) },
	{ "folder": "holy_city_plains", "base_name": "wagon_ruts", "width": 128, "height": 96, "variants": 1, "color": Color(0.50, 0.36, 0.22, 0.6) },
	{ "folder": "holy_city_plains", "base_name": "roadside_milestone", "width": 48, "height": 80, "variants": 1, "color": Color(0.55, 0.55, 0.55, 1.0) },
	{ "folder": "holy_city_plains", "base_name": "hoof_iron_accent", "width": 24, "height": 24, "variants": 1, "color": Color(0.28, 0.28, 0.32, 1.0) },
	{ "folder": "holy_city_plains", "base_name": "wildflower_cluster", "width": 48, "height": 48, "variants": 1, "color": Color(0.95, 0.40, 0.65, 1.0) },
	{ "folder": "holy_city_plains", "base_name": "distant_tent", "width": 96, "height": 80, "variants": 1, "color": Color(0.80, 0.70, 0.50, 1.0) },

	# --- Tier 3: glass_weald ---
	{ "folder": "glass_weald", "base_name": "glass_tree", "width": 160, "height": 192, "variants": 2, "color": Color(0.35, 0.80, 0.85, 1.0) },
	{ "folder": "glass_weald", "base_name": "memory_vine", "width": 96, "height": 96, "variants": 1, "color": Color(0.80, 0.30, 0.75, 1.0) },
	{ "folder": "glass_weald", "base_name": "prism_salt_cluster", "width": 48, "height": 64, "variants": 1, "color": Color(0.65, 0.90, 0.95, 1.0) },
	{ "folder": "glass_weald", "base_name": "floating_shard", "width": 32, "height": 32, "variants": 1, "color": Color(0.70, 0.85, 1.0, 0.8) },
	{ "folder": "glass_weald", "base_name": "cracked_arcane_pillar", "width": 128, "height": 128, "variants": 1, "color": Color(0.50, 0.45, 0.60, 1.0) },
]


func _init() -> void:
	var written_count: int = 0
	var skipped_count: int = 0
	for row in ELEMENT_TABLE:
		var folder_path: String = "%s/%s" % [BACKGROUND_ROOT, row["folder"]]
		var make_result: int = DirAccess.make_dir_recursive_absolute(folder_path)
		if make_result != OK and not DirAccess.dir_exists_absolute(folder_path):
			push_error("Could not create folder: %s" % folder_path)
			continue
		var variants: int = row["variants"]
		for variant_index in range(variants):
			var path: String = _variant_path(folder_path, row["base_name"], variants, variant_index)
			if not OVERWRITE and FileAccess.file_exists(path):
				print("skip (exists): %s" % path)
				skipped_count += 1
				continue
			var color: Color = _variant_color(row["color"], variant_index)
			var image := Image.create(row["width"], row["height"], false, Image.FORMAT_RGBA8)
			image.fill(color)
			var save_result: int = image.save_png(path)
			if save_result != OK:
				push_error("Failed to write: %s" % path)
				continue
			print("wrote: %s (%dx%d)" % [path, row["width"], row["height"]])
			written_count += 1
	print("---")
	print("Done. %d written, %d skipped." % [written_count, skipped_count])
	quit()


## Builds the variant file path. Single-variant elements get no numeric suffix;
## multi-variant elements get a 1-based, zero-padded `_NN` suffix.
func _variant_path(folder_path: String, base_name: String, variants: int, variant_index: int) -> String:
	if variants <= 1:
		return "%s/%s.png" % [folder_path, base_name]
	return "%s/%s_%02d.png" % [folder_path, base_name, variant_index + 1]


## Nudges value and alpha per variant index so variants are visibly distinct
## while staying clamped to a valid range.
func _variant_color(base_color: Color, variant_index: int) -> Color:
	if variant_index == 0:
		return base_color
	var value_shift: float = 0.10 * float(variant_index)
	var shifted := base_color
	shifted.r = clampf(shifted.r + value_shift, 0.0, 1.0)
	shifted.g = clampf(shifted.g + value_shift, 0.0, 1.0)
	shifted.b = clampf(shifted.b + value_shift, 0.0, 1.0)
	return shifted
