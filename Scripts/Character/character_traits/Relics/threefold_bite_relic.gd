class_name ThreefoldBiteRelic extends RelicEffect

const NON_ECHO_PENALTY: float = -0.30
const ECHOES_PER_BONUS: int = 3

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Threefold_Bite/Threefold_Bite.png")
	_title = "Threefold Bite"
	_magnitude_by_rarity = [0.60, 0.80, 1.00, 1.30, 1.70]
	_body = ("Every third Echo a single action produces deals +" +
			str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Damage that is not an Echo is reduced by 30%.")

func GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, p_resolver: BattleResolver) -> float:
	if(not p_resolver.IsResolvingEcho()):
		return NON_ECHO_PENALTY
	if(0 == p_resolver.EchoOrdinalThisAction() % ECHOES_PER_BONUS):
		return Magnitude()
	return 0.0
