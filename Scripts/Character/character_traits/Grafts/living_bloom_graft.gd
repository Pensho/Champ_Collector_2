class_name LivingBloomGraft extends GraftEffect

const MAX_CHARGES: int = 10
const CHARGE_PER_TURN: int = 1
const SPORE_ZONE_STATUS_DURATION: int = 1

const KNOWLEDGE_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.15,
	Types.Rarity.Rare: 0.20,
	Types.Rarity.Epic: 0.25,
	Types.Rarity.Legendary: 0.30,
}

var _bloom_zone_ID: int = -1

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_title = "Living Bloom"
	_body = ("Gains " + str(int(KNOWLEDGE_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100)) + "% Knowledge."
			+ "\nAt the start of combat, plants a Spore Bloom with " + str(MAX_CHARGES)
			+ " charges that regenerates allies standing in it and blights enemies."
			+ "\nThe Bloom regains " + str(CHARGE_PER_TURN) + " charge at the start of each of its turns.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var free_slots: Array[int] = p_resolver.GetZoneResolver().AvailableZoneIDs()
	if(free_slots.is_empty()):
		_bloom_zone_ID = -1
		return
	var zone_effect: ZoneEffect = ZoneEffect.new()
	zone_effect.charges = MAX_CHARGES
	zone_effect.on_trigger = SporeOnTrigger()
	_bloom_zone_ID = free_slots[0]
	p_resolver.GetZoneResolver().PlaceZone(_bloom_zone_ID, p_owner_ID, zone_effect, Types.Skill_Target.ZoneAll,
			p_resolver.GetEffectiveAttributes(p_owner_ID), "Living Bloom")

static func SporeOnTrigger() -> Array[SkillEffect]:
	var regeneration: ApplyBuffEffect = ApplyBuffEffect.new()
	regeneration.buff_type = Types.Buff_Type.Regeneration
	regeneration.duration = SPORE_ZONE_STATUS_DURATION
	regeneration.target = Types.Skill_Target.ZoneAlly
	var blight: ApplyDebuffEffect = ApplyDebuffEffect.new()
	blight.debuff_type = Types.Debuff_Type.Blight
	blight.duration = SPORE_ZONE_STATUS_DURATION
	blight.target = Types.Skill_Target.ZoneEnemy
	return [regeneration, blight]

func StartOfTurn(_p_owner_ID: int, p_resolver: BattleResolver) -> void:
	if(-1 == _bloom_zone_ID or not p_resolver.GetZoneResolver().HasZone(_bloom_zone_ID)):
		return
	p_resolver.GetZoneResolver().ReplenishZoneCharge(_bloom_zone_ID, CHARGE_PER_TURN, MAX_CHARGES)

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Knowledge: KNOWLEDGE_BONUS_PER_RARITY.get(p_rarity, 0.0)}
