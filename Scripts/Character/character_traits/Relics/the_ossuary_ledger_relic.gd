class_name TheOssuaryLedgerRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Ossuary_Ledger/The_Ossuary_Ledger.png")
	_title = "The Ossuary Ledger"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("When an ally dies, the wearer deals +" + str(roundi(Magnitude() * 100)) +
			"% damage for the rest of the battle.\n" +
			"Drawback: the wearer can never gain a buff, from any source (Severance, " +
			"permanently).")
