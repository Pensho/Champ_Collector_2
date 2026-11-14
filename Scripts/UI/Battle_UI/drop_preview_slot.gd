class_name DropPreviewSlot extends Control

@export var _texture_rect: TextureRect
@export var _label_type: Label
@export var _label_band: Label

## p_name replaces the loot type label, e.g. a gear drop's sub-type.
func Setup(p_entry: Dictionary, p_icon: Texture, p_name: String = "") -> void:
	_texture_rect.visible = null != p_icon
	_texture_rect.texture = p_icon
	var prefix: String = "" if p_entry["guaranteed"] else "Chance: "
	_label_type.text = prefix + (DropPreview.TypeLabel(p_entry["type"]) if p_name.is_empty() else p_name)
	_label_band.text = DropPreview.BandLabel(p_entry)
	_label_band.visible = not _label_band.text.is_empty()
