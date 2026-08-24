class_name TheLongSecondRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Long_Second/The_Long_Second.png")
	_title = "The Long Second"
	_magnitude_by_rarity = [0.20, 0.25, 0.30, 0.35, 0.45]
	_body = ("Forward turn-bar bumps the wearer grants an ally gain +" +
			str(roundi(Magnitude() * 100)) + "% increased effect.\n" +
			"Buffs placed by the wearer's team have 30% reduced effect.")
