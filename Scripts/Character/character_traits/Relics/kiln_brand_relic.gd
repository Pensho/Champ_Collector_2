class_name KilnBrandRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/Relics/Kiln_Brand/Kiln_Brand.png")
	_title = "Kiln Brand"
	_magnitude_by_rarity = [0.20, 0.30, 0.40, 0.50, 0.65]
	_body = ("Skills carrying a cooldown deal +" + str(roundi(Magnitude() * 100)) +
			"% damage.\n" +
			"Drawback: the wearer's damaging skills that can apply a debuff deal 40% less " +
			"damage.")
