class_name DraughtFedEdgeRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/Draught_Fed_Edge/Draught_Fed_Edge.png")
	_title = "Draught-Fed Edge"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("The first damaging skill cast after consuming a reagent deals +" +
			str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Drawback: reagents the wearer consumes have 40% less effect.")
