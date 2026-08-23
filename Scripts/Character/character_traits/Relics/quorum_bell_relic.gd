class_name QuorumBellRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Quorum_Bell/Quorum_Bell.png")
	_title = "Quorum Bell"
	_magnitude_by_rarity = [11.0, 13.0, 15.0, 17.0, 20.0]
	_body = ("While at least one zone stands on the turn bar, attribute buffs and " +
			"debuffs the wearer applies are +" + str(roundi(Magnitude())) +
			" percentage points stronger, adding to any other attribute amplification the " +
			"team supplies rather than replacing it. Defence, Critical Chance and Critical " +
			"Damage are excluded.\n" +
			"Compositional drawback: damaging skills carrying no cooldown deal 30% less " +
			"damage, for everyone on the wearer's team.")
