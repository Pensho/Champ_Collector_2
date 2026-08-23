class_name SunderplateNailRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Sunderplate_Nail/Sunderplate_Nail.png")
	_title = "Sunderplate Nail"
	_magnitude_by_rarity = [0.18, 0.20, 0.23, 0.27, 0.32]
	_body = ("The wearer's damaging skills treat the target's Defence as " +
			str(roundi(Magnitude() * 100)) + "% lower.\n" +
			"Compositional drawback: the wearer loses 10% of their max Health whenever " +
			"they gain a buff.")
