class_name PrismOfSmallFavorsRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Prism_of_Small_Favors/Prism_of_Small_Favors.png")
	_title = "Prism of Small Favors"
	_magnitude_by_rarity = [2.0, 2.0, 3.0, 3.0, 4.0]
	_body = ("Each buff the wearer holds, up to " + str(roundi(Magnitude())) +
			" of them, grants +12% points Critical Chance.\n" +
			"Buffs the wearer holds have half their effect.")
