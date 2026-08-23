class_name TheAnsweringBossRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Answering_Boss/The_Answering_Boss.png")
	_title = "The Answering Boss"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("While the wearer holds a Barrier, damaging skills deal +" +
			str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Drawback: the wearer's max Health is reduced by 30%.")
