class_name SignatorysSealRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Signatorys_Seal/Signatorys_Seal.png")
	_title = "Signatory's Seal"
	_magnitude_by_rarity = [2.0, 2.0, 3.0, 3.0, 4.0]
	_body = ("The first " + str(roundi(Magnitude())) +
			" debuffs applied to each enemy in a battle cannot be resisted.\n" +
			"The wearer can never resist debuffs.")
