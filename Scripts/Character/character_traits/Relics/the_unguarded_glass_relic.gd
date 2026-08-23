class_name TheUnguardedGlassRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Unguarded_Glass/The_Unguarded_Glass.png")
	_title = "The Unguarded Glass"
	_magnitude_by_rarity = [0.35, 0.45, 0.55, 0.70, 0.80]
	_body = ("While the wearer holds a buff granted by an ally, critical hits deal +" +
			str(roundi(Magnitude() * 100)) + "% Critical Damage.\n" +
			"Drawback: the wearer can hold at most one buff at a time, a new buff replaces " +
			"the one they hold.")
