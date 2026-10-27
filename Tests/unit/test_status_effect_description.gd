extends GutTest

func _Sanction() -> StatusEffectData:
	return load("res://Data/Status_Effects/Sanction.tres") as StatusEffectData

func test_sanction_shows_attacker_damage_from_raw_value_and_attributes_from_fraction() -> void:
	# 9 Infractions at a 4% rate: raw value 0.36, unamplified.
	var description: String = _Sanction().FormatDescription(0, 0.36, 0.36)
	assert_string_contains(description, "deal 72% more damage")
	assert_string_contains(description, "reduced by 18%")

func test_sanction_attribute_percent_follows_amplified_fraction_while_damage_does_not() -> void:
	# Attribute amplification raises the displayed fraction, never the attacker damage bucket.
	var description: String = _Sanction().FormatDescription(0, 0.46, 0.36)
	assert_string_contains(description, "deal 72% more damage")
	assert_string_contains(description, "reduced by 23%")

func test_attribute_percent_equals_percent_for_unit_weight_modifiers() -> void:
	var data: StatusEffectData = StatusEffectData.new()
	data.attribute_modifiers = {Types.Attribute.Attack: -1.0}
	data.description = "{percent} {attribute_percent}"
	assert_eq(data.FormatDescription(0, 0.25, 0.25), "25 25")
