@tool
extends EditorScript

## Data-driven generator for flat-color placeholder icon textures, following
## Scripts/Debug/generate_placeholder_textures.gd's recipe.
##
## Each row in ICON_TABLE describes one icon: a folder, a base name, a size, a base
## hue, and a rarity tier. The output PNG is the base hue blended toward that
## rarity's tint color, written to
## <ICON_ROOT>/<folder>/<base_name>_<rarity>.png.
##
## Existing files are skipped so hand-replaced real art is never clobbered; set
## OVERWRITE to true to force regeneration.
##
## Run headless:
##   godot --headless -s res://Scripts/Debug/generate_placeholder_icons.gd

const OVERWRITE: bool = false
const ICON_ROOT: String = "res://Assets/Champ_Collector/Icons"

# One row per reagent family. Each family gets one icon per rarity tier, all sharing
# this base hue blended toward the rarity's tint (see RARITY_TINTS).
#   folder, base_name, size, base_color
const REAGENT_FAMILY_TABLE: Array = [
	{ "folder": "Reagents/Tincture_Speed", "base_name": "Tincture_Speed", "size": 64,
			"color": Color(0.85, 0.75, 0.15, 1.0) },
	{ "folder": "Reagents/Tincture_Attack", "base_name": "Tincture_Attack", "size": 64,
			"color": Color(0.80, 0.30, 0.15, 1.0) },
	{ "folder": "Reagents/Tincture_Defence", "base_name": "Tincture_Defence", "size": 64,
			"color": Color(0.35, 0.45, 0.65, 1.0) },
	{ "folder": "Reagents/Tincture_Accuracy", "base_name": "Tincture_Accuracy", "size": 64,
			"color": Color(0.20, 0.65, 0.60, 1.0) },
	{ "folder": "Reagents/Tincture_Resistance", "base_name": "Tincture_Resistance", "size": 64,
			"color": Color(0.55, 0.40, 0.25, 1.0) },
	{ "folder": "Reagents/Tincture_Mysticism", "base_name": "Tincture_Mysticism", "size": 64,
			"color": Color(0.55, 0.30, 0.75, 1.0) },
	{ "folder": "Reagents/Tincture_Knowledge", "base_name": "Tincture_Knowledge", "size": 64,
			"color": Color(0.25, 0.55, 0.75, 1.0) },
	{ "folder": "Reagents/Tincture_CritChance", "base_name": "Tincture_CritChance", "size": 64,
			"color": Color(0.85, 0.35, 0.55, 1.0) },
	{ "folder": "Reagents/Tincture_CritDamage", "base_name": "Tincture_CritDamage", "size": 64,
			"color": Color(0.70, 0.15, 0.20, 1.0) },
	{ "folder": "Reagents/Restorative_Draught", "base_name": "Restorative_Draught", "size": 64,
			"color": Color(0.35, 0.75, 0.40, 1.0) },
	{ "folder": "Reagents/Purging_Tonic", "base_name": "Purging_Tonic", "size": 64,
			"color": Color(0.30, 0.80, 0.65, 1.0) },
	{ "folder": "Reagents/Thiefs_Regret", "base_name": "Thiefs_Regret", "size": 64,
			"color": Color(0.40, 0.20, 0.50, 1.0) },
	{ "folder": "Reagents/Rewinding_Grit", "base_name": "Rewinding_Grit", "size": 64,
			"color": Color(0.80, 0.65, 0.20, 1.0) },
	{ "folder": "Reagents/Second_Wind_Phial", "base_name": "Second_Wind_Phial", "size": 64,
			"color": Color(0.40, 0.70, 0.90, 1.0) },
	{ "folder": "Reagents/Zone_Dissolving_Salts", "base_name": "Zone_Dissolving_Salts", "size": 64,
			"color": Color(0.60, 0.60, 0.60, 1.0) },
	{ "folder": "Reagents/Unrefined_Residue", "base_name": "Unrefined_Residue", "size": 64,
			"color": Color(0.45, 0.50, 0.30, 1.0) },
	{ "folder": "Reagents/Fractured_Idol", "base_name": "Fractured_Idol", "size": 64,
			"color": Color(0.35, 0.12, 0.12, 1.0) },
]

# Rarity tier order, tint color, and blend strength (how far the base hue shifts
# toward the tint). Blend strength increases with rarity.
const RARITY_TINTS: Array = [
	{ "name": "Uncommon", "tint": Color(0.20, 0.80, 0.30, 1.0), "strength": 0.15 },
	{ "name": "Rare", "tint": Color(0.20, 0.50, 0.90, 1.0), "strength": 0.30 },
	{ "name": "Epic", "tint": Color(0.60, 0.20, 0.85, 1.0), "strength": 0.45 },
	{ "name": "Legendary", "tint": Color(0.95, 0.55, 0.10, 1.0), "strength": 0.60 },
]


func _run() -> void:
	var written_count: int = 0
	var skipped_count: int = 0
	for family_row in REAGENT_FAMILY_TABLE:
		var folder_path: String = "%s/%s" % [ICON_ROOT, family_row["folder"]]
		var make_result: int = DirAccess.make_dir_recursive_absolute(folder_path)
		if make_result != OK and not DirAccess.dir_exists_absolute(folder_path):
			push_error("Could not create folder: %s" % folder_path)
			continue
		for rarity_row in RARITY_TINTS:
			var path: String = "%s/%s_%s.png" % [folder_path, family_row["base_name"], rarity_row["name"]]
			if not OVERWRITE and FileAccess.file_exists(path):
				print("skip (exists): %s" % path)
				skipped_count += 1
				continue
			var color: Color = _rarity_tinted_color(family_row["color"], rarity_row)
			var size: int = family_row["size"]
			var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
			image.fill(color)
			var save_result: int = image.save_png(path)
			if save_result != OK:
				push_error("Failed to write: %s" % path)
				continue
			print("wrote: %s (%dx%d)" % [path, size, size])
			written_count += 1
	print("---")
	print("Done. %d written, %d skipped." % [written_count, skipped_count])


## Blends a family's base hue toward a rarity tier's tint color by that tier's
## blend strength, so every reagent family reads as one hue family across rarities
## while still visibly distinguishing rarity at a glance.
func _rarity_tinted_color(base_color: Color, rarity_row: Dictionary) -> Color:
	var tint: Color = rarity_row["tint"]
	var strength: float = rarity_row["strength"]
	return base_color.lerp(tint, strength)
