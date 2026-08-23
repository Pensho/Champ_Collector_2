class_name TheSolventMarkRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Solvent_Mark/The_Solvent_Mark.png")
	_title = "The Solvent Mark"
	_magnitude_by_rarity = [0.45, 0.50, 0.55, 0.60, 0.70]
	_body = ("Unravel, Expose Weakness, Blight and Blind applied by the wearer are +" +
			str(roundi(Magnitude() * 100)) + "% stronger, and none of the four can be " +
			"applied to the wearer.\n" +
			"Drawback: debuffs affecting the wearer have double magnitude.")
