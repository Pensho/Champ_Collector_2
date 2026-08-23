class_name TheLongFurrowRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Long_Furrow/The_Long_Furrow.png")
	_title = "The Long Furrow"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.55]
	_body = ("Rending Charge cast at 4 or 5 sections of turn-bar distance resolves a second " +
			"time, at " + str(roundi(Magnitude() * 100)) + "% strength.\n" +
			"Drawback: Rending Charge can never critically hit.")
