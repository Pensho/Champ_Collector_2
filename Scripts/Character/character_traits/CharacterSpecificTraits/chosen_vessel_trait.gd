class_name ChosenVesselTrait extends CharacterTrait

const POWER_BONUS: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.15,
	Types.Rarity.Rare: 0.20,
	Types.Rarity.Epic: 0.25,
	Types.Rarity.Legendary: 0.30,
}

const DEVOTION_BONUS: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.10,
	Types.Rarity.Rare: 0.13,
	Types.Rarity.Epic: 0.16,
	Types.Rarity.Legendary: 0.20,
}

const DRAIN_FRACTION: float = 0.05
const ATTUNE_DURATION: int = 3

var _power_bonus: float = 0.0
var _devotion_bonus: float = 0.0
var _devotion_count: int = 0
var _vessel_ID: int = -1

static func GetPowerBonus(p_rarity: Types.Rarity) -> float:
	return POWER_BONUS.get(p_rarity, 0.0)

static func GetDevotionBonus(p_rarity: Types.Rarity) -> float:
	return DEVOTION_BONUS.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_power_bonus = GetPowerBonus(p_rarity)
	_devotion_bonus = GetDevotionBonus(p_rarity)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Chosen_Vessel_Trait/chosen_vessel_trait.png"
	)
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Ally_Death] = Callable(self, "OnAllyDeath")

	_title = "Chosen Vessel"
	_body = "At the start of combat, marks a random ally as the Vessel. Every non-basic" \
			+ " skill drains 5% of the Vessel's max Health for a " + str(_power_bonus * 100) + "% damage bonus." \
			+ " If the Vessel dies, the Cultist gains Attune for 3 turns, a new Vessel is marked, and" \
			+ " the Cultist permanently gains " + str(_devotion_bonus * 100) + "% damage for the rest of the fight."

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_devotion_count = 0
	_MarkNewVessel(p_owner_ID, p_resolver)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	if(-1 == _vessel_ID or not _IsNonBasicSkill(p_owner_ID, p_skill_name, p_resolver)):
		return result

	var vessel: Character = p_resolver.GetCharacters()[_vessel_ID]
	var drain: int = int(ceil(p_resolver.GetMaxHealth(_vessel_ID) * DRAIN_FRACTION))
	p_resolver.SetCurrentHealth(_vessel_ID, vessel._current_health - drain)
	p_resolver.EmitTraitText(_vessel_ID, "Sacrificed", Color(0.5, 0.0, 0.3, 1.0))
	result._damage_multiplier = 1.0 + _power_bonus
	return result

func OnAllyDeath(p_owner_ID: int, p_dead_ally_ID: int, p_resolver: BattleResolver) -> void:
	if(p_dead_ally_ID != _vessel_ID):
		return
	var attune: StatusEffects.Buff = StatusEffects.Buff.new()
	attune.type = Types.Buff_Type.Attune
	attune.duration = ATTUNE_DURATION
	attune.name = "Attune"
	p_resolver.GetStatusResolver().ApplyBuff(p_owner_ID, attune)
	_devotion_count += 1
	p_resolver.EmitTraitText(p_owner_ID, "Devotion", Color(0.5, 0.0, 0.3, 1.0))
	_MarkNewVessel(p_owner_ID, p_resolver)

func GetOutgoingDamageBonus(
		_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
	return _devotion_bonus * _devotion_count

func GetConditionCount(
		_p_owner_ID: int,
		_p_target_ID: int,
		p_source: Types.Trait_Count_Source,
		p_resolver: BattleResolver) -> float:
	if(Types.Trait_Count_Source.Trait_Condition != p_source):
		return 0.0
	if(-1 == _vessel_ID):
		return 0.0
	var vessel: Character = p_resolver.GetCharacters().get(_vessel_ID)
	if(null == vessel or vessel._current_health <= 0):
		return 0.0
	var max_health: int = p_resolver.GetMaxHealth(_vessel_ID)
	if(max_health <= 0):
		return 0.0
	return 1.0 if float(vessel._current_health) / float(max_health) < 0.5 else 0.0

func _MarkNewVessel(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	allies.erase(p_owner_ID)
	if(allies.is_empty()):
		_vessel_ID = -1
		return
	_vessel_ID = allies[p_resolver.GetRandom().randi_range(0, allies.size() - 1)]

func _IsNonBasicSkill(p_owner_ID: int, p_skill_name: String, p_resolver: BattleResolver) -> bool:
	for skill in p_resolver.GetCharacters()[p_owner_ID]._skills:
		if(skill.name == p_skill_name):
			return skill.cooldown > 0
	return false
