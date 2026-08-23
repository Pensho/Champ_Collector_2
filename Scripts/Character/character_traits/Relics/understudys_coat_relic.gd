class_name UnderstudysCoatRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Understudys_Coat/Understudys_Coat.png")
	_title = "Understudy's Coat"
	_magnitude_by_rarity = [0.85, 0.80, 0.75, 0.70, 0.60]
	_body = ("Enemy single-target skills aimed at any other ally with the lowest " +
			"current Health strike the wearer instead, at " + str(roundi(Magnitude() * 100)) +
			"% of the damage.\n" +
			"Drawback: the wearer's damaging skills deal 35% less damage.")
