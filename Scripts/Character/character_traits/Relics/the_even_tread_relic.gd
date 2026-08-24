class_name TheEvenTreadRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/The_Even_Tread/The_Even_Tread.png")
	_title = "The Even Tread"
	_magnitude_by_rarity = [0.50, 0.55, 0.60, 0.70, 0.85]
	_body = ("Buffs the wearer applies are +" + str(roundi(Magnitude() * 100)) +
			"% stronger.\n" +
			"The wearer's allies cannot critically hit.")
