class_name ThePlantedHeelRelic extends RelicEffect

const BIG_HIT_FRACTION: float = 0.15
const TARGETING_DRAWBACK: float = 1.5

var _owner_ID: int = -1
var _resolver: BattleResolver = null
var _pending_bonus: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Planted_Heel/The_Planted_Heel.png")
	_title = "The Planted Heel"
	_magnitude_by_rarity = [0.30, 0.35, 0.40, 0.50, 0.65]
	_body = ("After the wearer takes a single hit exceeding 15% of their max Health, " +
			"their next damaging skill deals +" + str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Enemies target the wearer 50% more likely.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

## A single hit's own size isn't a hook parameter (OnDamageTaken fires before mitigation is
## known), so this reads the resolver's result stream instead, the same pattern
## StandingRecordTrait uses to watch events its hook vocabulary doesn't carry as arguments.
func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_owner_ID = p_owner_ID
	_resolver = p_resolver
	_pending_bonus = false
	if(not p_resolver.result_produced.is_connected(_OnResultProduced)):
		p_resolver.result_produced.connect(_OnResultProduced)

func _OnResultProduced(p_result: CombatResult) -> void:
	if(CombatResult.Kind.Damage != p_result.kind or p_result.target_ID != _owner_ID or p_result.amount <= 0):
		return
	var max_health: int = _resolver.GetMaxHealth(_owner_ID)
	if(max_health > 0 and float(p_result.amount) > BIG_HIT_FRACTION * float(max_health)):
		_pending_bonus = true

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result := TraitSkillResult.new()
	if(not _pending_bonus or not _IsDamagingSkill(p_owner_ID, p_skill_name, p_resolver)):
		return result
	_pending_bonus = false
	result._damage_multiplier = 1.0 + Magnitude()
	return result

func _IsDamagingSkill(p_owner_ID: int, p_skill_name: String, p_resolver: BattleResolver) -> bool:
	for skill: Skill in p_resolver.GetCharacters()[p_owner_ID]._skills:
		if(skill.name == p_skill_name):
			return skill.effects.any(func(effect: SkillEffect) -> bool: return effect is DamageEffect)
	return false

func GetTargetingPriorityMultiplier() -> float:
	return TARGETING_DRAWBACK
