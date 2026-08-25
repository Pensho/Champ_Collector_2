class_name TheSolventMarkRelic extends RelicEffect

const AMPLIFIED_DEBUFF_TYPES: Array[Types.Debuff_Type] = [
	Types.Debuff_Type.Unravel,
	Types.Debuff_Type.Expose_Weakness,
	Types.Debuff_Type.Blight,
	Types.Debuff_Type.Blind,
]
const INCOMING_DEBUFF_MULTIPLIER: float = 2.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Solvent_Mark/The_Solvent_Mark.png")
	_title = "The Solvent Mark"
	_magnitude_by_rarity = [0.45, 0.50, 0.55, 0.60, 0.70]
	_body = ("Unravel, Expose Weakness, Blight and Blind applied by the wearer are +" +
			str(roundi(Magnitude() * 100)) + "% stronger, and none of the four can be " +
			"applied to the wearer.\n" +
			"Debuffs affecting the wearer have double effect.")
	_execution_steps[Types.Combat_Event.Debuff_Received] = Callable(self, "OnDebuffReceived")

func GetAppliedStatusValue(
		p_owner_ID: int, p_target_ID: int, p_debuff_type: Types.Debuff_Type, p_resolver: BattleResolver) -> float:
	if(not AMPLIFIED_DEBUFF_TYPES.has(p_debuff_type)):
		return -1.0
	var data: StatusEffectData = StatusEffectRegistry.DebuffData(p_debuff_type)
	if(null == data):
		return -1.0
	var base_value: float = p_resolver.GetStatusResolver().SnapshotStatusValue(data, p_owner_ID, p_target_ID)
	return base_value * (1.0 + Magnitude())

func BlocksIncomingDebuffType(p_debuff_type: Types.Debuff_Type) -> bool:
	return AMPLIFIED_DEBUFF_TYPES.has(p_debuff_type)

func OnDebuffReceived(
		_p_owner_ID: int, p_debuff: StatusEffects.Debuff, _p_resolver: BattleResolver) -> void:
	p_debuff.value *= INCOMING_DEBUFF_MULTIPLIER
