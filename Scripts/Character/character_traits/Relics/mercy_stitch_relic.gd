class_name MercyStitchRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Mercy_Stitch/Mercy_Stitch.png")
	_title = "Mercy Stitch"
	_magnitude_by_rarity = [0.20, 0.25, 0.30, 0.35, 0.45]
	_body = ("Once per battle, damage that would take the wearer below 25% Health " +
			"instead leaves them there, and heals them for " + str(roundi(Magnitude() * 100)) +
			"% of max Health.\n" +
			"Drawback: while at or below 40% Health, the wearer's damaging skills deal " +
			"40% less damage.")
