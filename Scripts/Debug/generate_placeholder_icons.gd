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

# One row per batch-1 status effect (Plan_Status_Effect_Implementation.md). Status
# effects aren't rarity-tiered, so each row writes a single flat-color PNG rather than
# one per RARITY_TINTS entry. Buffs use a green/blue hue family, debuffs a red/purple
# one; each effect gets a distinct hue within its family.
#   folder, base_name, size, color
const STATUS_EFFECT_TABLE: Array = [
	# Debuffs (red/purple family)
	{ "folder": "Status_Effects/Suppress", "base_name": "Suppress", "size": 64,
			"color": Color(0.55, 0.20, 0.65, 1.0) },
	{ "folder": "Status_Effects/Slow", "base_name": "Slow", "size": 64,
			"color": Color(0.70, 0.30, 0.15, 1.0) },
	{ "folder": "Status_Effects/Blind", "base_name": "Blind", "size": 64,
			"color": Color(0.60, 0.15, 0.15, 1.0) },
	{ "folder": "Status_Effects/Unravel", "base_name": "Unravel", "size": 64,
			"color": Color(0.65, 0.25, 0.45, 1.0) },
	{ "folder": "Status_Effects/Confound", "base_name": "Confound", "size": 64,
			"color": Color(0.45, 0.15, 0.55, 1.0) },
	{ "folder": "Status_Effects/Exposed_Facet", "base_name": "Exposed_Facet", "size": 64,
			"color": Color(0.80, 0.35, 0.20, 1.0) },
	{ "folder": "Status_Effects/Cracked_Facet", "base_name": "Cracked_Facet", "size": 64,
			"color": Color(0.75, 0.10, 0.30, 1.0) },
	{ "folder": "Status_Effects/Sequence_Lock", "base_name": "Sequence_Lock", "size": 64,
			"color": Color(0.50, 0.10, 0.10, 1.0) },
	{ "folder": "Status_Effects/Bleed", "base_name": "Bleed", "size": 64,
			"color": Color(0.65, 0.05, 0.05, 1.0) },
	{ "folder": "Status_Effects/Plague", "base_name": "Plague", "size": 64,
			"color": Color(0.40, 0.30, 0.10, 1.0) },
	{ "folder": "Status_Effects/Blight", "base_name": "Blight", "size": 64,
			"color": Color(0.45, 0.15, 0.30, 1.0) },
	{ "folder": "Status_Effects/Temporal_Leak", "base_name": "Temporal_Leak", "size": 64,
			"color": Color(0.35, 0.15, 0.45, 1.0) },
	# Buffs (green/blue family)
	{ "folder": "Status_Effects/Attune", "base_name": "Attune", "size": 64,
			"color": Color(0.30, 0.55, 0.80, 1.0) },
	{ "folder": "Status_Effects/Haste", "base_name": "Haste", "size": 64,
			"color": Color(0.20, 0.75, 0.55, 1.0) },
	{ "folder": "Status_Effects/True_Aim", "base_name": "True_Aim", "size": 64,
			"color": Color(0.15, 0.65, 0.35, 1.0) },
	{ "folder": "Status_Effects/Clarity", "base_name": "Clarity", "size": 64,
			"color": Color(0.35, 0.80, 0.75, 1.0) },
	{ "folder": "Status_Effects/Insight", "base_name": "Insight", "size": 64,
			"color": Color(0.20, 0.45, 0.75, 1.0) },
	{ "folder": "Status_Effects/Vigor", "base_name": "Vigor", "size": 64,
			"color": Color(0.25, 0.70, 0.30, 1.0) },
	{ "folder": "Status_Effects/Keen_Edge", "base_name": "Keen_Edge", "size": 64,
			"color": Color(0.40, 0.70, 0.90, 1.0) },
	{ "folder": "Status_Effects/Lethal_Precision", "base_name": "Lethal_Precision", "size": 64,
			"color": Color(0.15, 0.55, 0.85, 1.0) },
	{ "folder": "Status_Effects/Frenzy", "base_name": "Frenzy", "size": 64,
			"color": Color(0.60, 0.75, 0.20, 1.0) },
	{ "folder": "Status_Effects/Opportunist", "base_name": "Opportunist", "size": 64,
			"color": Color(0.20, 0.60, 0.65, 1.0) },
	{ "folder": "Status_Effects/Regeneration", "base_name": "Regeneration", "size": 64,
			"color": Color(0.25, 0.80, 0.45, 1.0) },
	{ "folder": "Status_Effects/Exhert", "base_name": "Exhert", "size": 64,
			"color": Color(0.15, 0.60, 0.55, 1.0) },
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
	for status_row in STATUS_EFFECT_TABLE:
		var folder_path: String = "%s/%s" % [ICON_ROOT, status_row["folder"]]
		var make_result: int = DirAccess.make_dir_recursive_absolute(folder_path)
		if make_result != OK and not DirAccess.dir_exists_absolute(folder_path):
			push_error("Could not create folder: %s" % folder_path)
			continue
		var path: String = "%s/%s.png" % [folder_path, status_row["base_name"]]
		if not OVERWRITE and FileAccess.file_exists(path):
			print("skip (exists): %s" % path)
			skipped_count += 1
			continue
		var size: int = status_row["size"]
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		image.fill(status_row["color"])
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
