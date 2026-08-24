class_name LanternOfTheStandingWardRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/Relics/" +
			"Lantern_of_the_Standing_Ward/Lantern_of_the_Standing_Ward.png")
	_title = "Lantern of the Standing Ward"
	_magnitude_by_rarity = [0.40, 0.45, 0.50, 0.60, 0.75]
	_body = ("The first charge spent by a zone the wearer placed Echoes once, at " +
			str(roundi(Magnitude() * 100)) + "% strength.\n" +
			"Every reagent consumed by anyone on the wearer's team has 50% effect.")
