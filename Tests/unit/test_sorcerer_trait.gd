extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _trait: SorcererTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func before_each() -> void:
	_character = Character.new()
	_character._current_health = 10
	_character._attributes[Types.Attribute.Health] = 10
	_character._attributes[Types.Attribute.Mysticism] = 100
	_trait = SorcererTrait.new()
	_characters = {0: _character}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], []))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_character._rarity = p_rarity
	_trait.Init(p_rarity)

## One skill turn as the resolver runs it: the cast hook, then End_Turn after the Echoes.
func _CastAndEndTurn(p_skill_name: String = "Zap") -> void:
	var attributes: Dictionary[Types.Attribute, int] = {Types.Attribute.Mysticism: 100}
	_trait.OnSkillCast(0, [], p_skill_name, attributes, _resolver)
	_trait.EndOfTurn(0, _resolver)

func _AddCharacter(p_ID: int, p_is_enemy: bool) -> Character:
	var other: Character = TestFactory.make_character()
	other._current_health = 10
	other._rarity = Types.Rarity.Epic
	_characters[p_ID] = other
	var allies: Array[int] = [0]
	var enemies: Array[int] = []
	for character_ID: int in _characters:
		if(0 == character_ID):
			continue
		if(p_is_enemy and character_ID == p_ID):
			enemies.append(character_ID)
		else:
			allies.append(character_ID)
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new(allies, enemies))
	return other

# --- Instability accrual ---

func test_instability_is_gained_at_end_of_turn_not_on_cast() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.OnSkillCast(0, [], "Zap", {Types.Attribute.Mysticism: 100}, _resolver)
	assert_eq(_trait._instability_stacks, 0, "The cast itself grants nothing; the gain follows the action")
	_trait.EndOfTurn(0, _resolver)
	assert_eq(_trait._instability_stacks, 1)

func test_end_of_turn_without_a_cast_grants_nothing() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait.EndOfTurn(0, _resolver)
	assert_eq(_trait._instability_stacks, 0)

func test_five_skills_reach_max_without_a_surge() -> void:
	_InitTrait(Types.Rarity.Epic)
	var ally: Character = _AddCharacter(1, false)
	for i in SorcererTrait.MAX_INSTABILITY_STACKS:
		_CastAndEndTurn()
	assert_eq(_trait._instability_stacks, SorcererTrait.MAX_INSTABILITY_STACKS)
	assert_eq(ally._current_health, 10, "Reaching 5 Instability does not itself release a Surge")

func test_reagent_grants_two_instability_and_returns_amplification() -> void:
	_InitTrait(Types.Rarity.Legendary)
	var amplification: float = _trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_eq(_trait._instability_stacks, 2)
	assert_eq(amplification, 0.50)

# --- Surge ---

func test_sixth_skill_releases_a_surge_on_everyone_and_resets() -> void:
	_InitTrait(Types.Rarity.Epic)
	var ally: Character = _AddCharacter(1, false)
	var enemy: Character = _AddCharacter(2, true)
	_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS
	_CastAndEndTurn()
	assert_lt(ally._current_health, 10, "Surge damages allies")
	assert_lt(enemy._current_health, 10, "Surge damages enemies")
	assert_lt(_character._current_health, 10, "Surge damages the Sorcerer")
	assert_eq(_trait._instability_stacks, 0, "Surge resets Instability")

func test_reagent_past_max_releases_a_surge() -> void:
	_InitTrait(Types.Rarity.Epic)
	var enemy: Character = _AddCharacter(1, true)
	_trait._instability_stacks = 4
	_trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_lt(enemy._current_health, 10)
	assert_eq(_trait._instability_stacks, 0)

func test_reagent_reaching_exactly_max_does_not_surge() -> void:
	_InitTrait(Types.Rarity.Epic)
	var enemy: Character = _AddCharacter(1, true)
	_trait._instability_stacks = 3
	_trait.OnReagentConsumed(0, ReagentData.new(), _resolver)
	assert_eq(enemy._current_health, 10)
	assert_eq(_trait._instability_stacks, SorcererTrait.MAX_INSTABILITY_STACKS)

func test_surge_never_crits() -> void:
	_InitTrait(Types.Rarity.Epic)
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000  # Health(1000) x ATTRIBUTE_HEALTH_MULTIPLIER(4)
	enemy._rarity = Types.Rarity.Epic
	_characters[1] = enemy
	_character._attributes[Types.Attribute.CritChance] = 100
	_character._attributes[Types.Attribute.CritDamage] = 500
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))
	_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS

	_CastAndEndTurn()

	var damage_taken: int = 4000 - enemy._current_health
	# A non-crit hit lands well under 300 here; a crit (CritDamage 500) would land around 700+.
	assert_true(damage_taken > 0 and damage_taken < 300, "Surge must never roll a critical hit")

func test_stacks_reset_at_battle_start() -> void:
	_trait._instability_stacks = 3
	_trait.StartOfBattle(0, _resolver)
	assert_eq(_trait._instability_stacks, 0, "Instability should not persist between combats")

# --- Cataclysm's Echoes, through the real resolver ---

func _make_skill(p_name: String) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = p_name
	skill.target = Types.Skill_Target.Single_Enemy
	skill.cooldown = 1
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	var burn: ApplyDebuffEffect = ApplyDebuffEffect.new()
	burn.debuff_type = Types.Debuff_Type.Burning
	burn.duration = 2
	skill.effects = [damage, burn]
	return skill

## A Sorcerer with Cataclysm and one other skill, and a durable enemy target, with
## StartOfBattle already broadcast so the trait's Skill_Resolved subscription is live.
func _make_echo_setup() -> Dictionary:
	var caster: Character = TestFactory.make_character()
	caster._current_health = 10
	caster._attributes[Types.Attribute.Mysticism] = 100
	caster._rarity = Types.Rarity.Rare
	var caster_trait: SorcererTrait = SorcererTrait.new()
	caster_trait.Init(Types.Rarity.Rare)
	caster._trait = caster_trait
	caster._skills = [_make_skill(SorcererTrait.ECHOING_SKILL_NAME), _make_skill("Bolt")]
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000  # Health(1000) x ATTRIBUTE_HEALTH_MULTIPLIER(4)
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	return {"trait": caster_trait, "resolver": resolver, "caster": caster}

func _damage_against(p_results: Array[CombatResult], p_target_ID: int) -> Array[CombatResult]:
	return p_results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind and p_target_ID == r.target_ID)

func test_cataclysm_echoes_once_per_instability_held_with_compounding() -> void:
	var setup: Dictionary = _make_echo_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait._instability_stacks = 3

	var damage: Array[CombatResult] = _damage_against(resolver.ResolveSkill(0, [1], 0), 1)

	assert_eq(damage.size(), 4, "The cast plus one Echo per Instability held")
	assert_lt(damage[1].amount, damage[0].amount, "The first Echo resolves at REPEAT_FRACTION")
	assert_lt(damage[1].amount, damage[2].amount, "Each later Echo compounds on the previous")
	assert_eq(damage[1].cascade_depth, 1)
	assert_eq(caster_trait._instability_stacks, 4, "Cataclysm reads Instability; it does not spend it")

func test_first_echo_bucket_carries_the_repeat_fraction() -> void:
	var setup: Dictionary = _make_echo_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait._instability_stacks = 1

	var damage: Array[CombatResult] = _damage_against(resolver.ResolveSkill(0, [1], 0), 1)

	var buckets: Dictionary[StringName, float] = damage[1].combined_damage_modifier.Buckets()
	var repeat_key: StringName = StringName(SorcererTrait.ECHOING_SKILL_NAME + " (repeat)")
	assert_eq(buckets.get(repeat_key, 0.0), SorcererTrait.REPEAT_FRACTION - 1.0)

func test_other_skills_never_echo() -> void:
	var setup: Dictionary = _make_echo_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait._instability_stacks = 4

	var damage: Array[CombatResult] = _damage_against(resolver.ResolveSkill(0, [1], 1), 1)

	assert_eq(damage.size(), 1)

func test_cataclysm_at_max_echoes_five_times_then_surges() -> void:
	var setup: Dictionary = _make_echo_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait._instability_stacks = SorcererTrait.MAX_INSTABILITY_STACKS

	var damage: Array[CombatResult] = _damage_against(resolver.ResolveSkill(0, [1], 0), 1)

	assert_eq(damage.size(), 7, "The cast, five Echoes, then the Surge")
	assert_eq(damage[5].cascade_depth, 1, "The fifth Echo resolves before the Surge")
	assert_eq(damage[6].cascade_depth, 0, "The Surge lands last, outside the cascade")
	assert_eq(caster_trait._instability_stacks, 0)

func test_repeat_does_not_reapply_a_stackable_debuff() -> void:
	var setup: Dictionary = _make_echo_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait._instability_stacks = 2

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var applied: Array[CombatResult] = results.filter(func(r: CombatResult) -> bool:
			return (CombatResult.Kind.Status_Applied == r.kind and not r.is_buff
					and Types.Debuff_Type.Burning == r.debuff_type))
	assert_eq(applied.size(), 1, "Echoes re-run DamageEffects only; the debuff still applies once")

func test_echo_count_does_not_carry_into_the_next_cast() -> void:
	var setup: Dictionary = _make_echo_setup()
	var caster_trait: SorcererTrait = setup["trait"]
	var resolver: BattleResolver = setup["resolver"]
	caster_trait._instability_stacks = 2

	resolver.ResolveSkill(0, [1], 0)
	var second: Array[CombatResult] = _damage_against(resolver.ResolveSkill(0, [1], 1), 1)

	assert_eq(caster_trait._echoes_for_this_cast, 0)
	assert_eq(second.size(), 1)
