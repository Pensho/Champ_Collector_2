class_name AshOfferingTrait extends CharacterTrait

const DAMAGE_BONUS_PER_STACK: float = 0.4
const SERMON_SKILL_NAME: String = "Cinder Sermon"
const FUELING_ALLY_NAME: String = "Cinder Husk"

var _pending_stacks: int = 0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Ash_Offering/Ash_Offering.png"
	)
	_execution_steps[Types.Combat_Event.Ally_Death] = Callable(self, "OnAllyDeath")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_title = "Ash Offering"
	_body = "When an ally Cinder Husk dies, the user's next Cinder Sermon deals +40% damage." \
			+ " Multiple deaths stack; the bonus is consumed by that one Sermon."

func RefreshVisuals(_p_character_repr: CharacterRepresentation) -> void:
	pass

func OnAllyDeath(_p_owner_ID: int, p_dead_ally_ID: int, p_resolver: BattleResolver) -> void:
	var dead_ally: Character = p_resolver.GetCharacters()[p_dead_ally_ID]
	if(FUELING_ALLY_NAME != dead_ally._name):
		return
	_pending_stacks += 1

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	if(SERMON_SKILL_NAME != p_skill_name or 0 == _pending_stacks):
		return result
	result._damage_multiplier = 1.0 + DAMAGE_BONUS_PER_STACK * _pending_stacks
	_pending_stacks = 0
	return result
