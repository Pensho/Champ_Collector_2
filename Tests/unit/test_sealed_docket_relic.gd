extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _equipped_IDs: Array[int] = []

func after_each() -> void:
	for id in _equipped_IDs:
		if(main.GetInstance()._item_collection._items.has(id)):
			main.GetInstance()._item_collection._items[id].free()
			main.GetInstance()._item_collection._items.erase(id)
	_equipped_IDs.clear()

func _equip_relic(p_character: Character, p_slot: Types.Slot, p_relic_effect: RelicEffect) -> void:
	var equipment: Equipment = Equipment.new()
	equipment._slot = p_slot
	equipment._relic_effect = p_relic_effect
	var id: int = main.GetInstance()._item_collection.CreateNextInstanceID()
	main.GetInstance()._item_collection._items[id] = equipment
	p_character._held_items[p_slot] = id
	_equipped_IDs.append(id)

func _make_setup(p_rarity: Types.Rarity) -> Dictionary:
	var wearer: Character = TestFactory.make_character()
	var relic: TheSealedDocketRelic = TheSealedDocketRelic.new()
	relic.Init(p_rarity)
	wearer._trait = relic
	var ally: Character = TestFactory.make_character()
	var enemy: Character = TestFactory.make_character()
	var characters: Dictionary[int, Character] = {0: wearer, 1: ally, 2: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], [2]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	return {"relic": relic, "resolver": resolver}

func _strength_contributions_for(p_resolver: BattleResolver, p_subject_ID: int) -> Array[Dictionary]:
	var cascade: CascadeResolver = p_resolver.GetCascadeResolver()
	var seen: Array[Dictionary] = []
	cascade.Subscribe(Types.Cascade_Trigger.Status_Expired, &"TestListener",
			func(_e: CascadeEvent) -> bool: return true,
			func(_e: CascadeEvent) -> void: seen.append(p_resolver.CurrentEchoStrengthContributions()))
	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Status_Expired)
	event.subject_ID = p_subject_ID
	p_resolver._BeginBatch()
	cascade.Post(event)
	p_resolver._EndBatch()
	return seen

func test_halves_the_wearers_own_echo() -> void:
	var setup: Dictionary = _make_setup(Types.Rarity.Legendary)
	var resolver: BattleResolver = setup["resolver"]

	var seen: Array[Dictionary] = _strength_contributions_for(resolver, 0)

	assert_eq(seen, [{&"TheSealedDocketRelic": -0.5}], "The wearer's own Echoes are halved too")

func test_halves_an_allys_echo() -> void:
	var setup: Dictionary = _make_setup(Types.Rarity.Legendary)
	var resolver: BattleResolver = setup["resolver"]

	var seen: Array[Dictionary] = _strength_contributions_for(resolver, 1)

	assert_eq(seen, [{&"TheSealedDocketRelic": -0.5}], "An ally's Echo should also resolve at half strength")

func test_does_not_affect_an_enemys_echo() -> void:
	var setup: Dictionary = _make_setup(Types.Rarity.Legendary)
	var resolver: BattleResolver = setup["resolver"]

	var seen: Array[Dictionary] = _strength_contributions_for(resolver, 2)

	assert_eq(seen, [{}], "An enemy's Echo must be untouched by the wearer's team-wide drawback")

func test_drawback_is_flat_not_laddered() -> void:
	for rarity in [Types.Rarity.Common, Types.Rarity.Legendary]:
		var setup: Dictionary = _make_setup(rarity)
		var resolver: BattleResolver = setup["resolver"]

		var seen: Array[Dictionary] = _strength_contributions_for(resolver, 0)

		assert_eq(seen, [{&"TheSealedDocketRelic": -0.5}], "Rarity %s" % Types.RarityName(rarity))

## The drawback must scope by the Echo's producer, not by whoever the Echo lands on: a
## Comorbidity re-tick's subject is the debuff-bearing enemy, but the debuff's source (the
## wearer) is who the drawback should check.
func test_halves_a_comorbidity_retick_sourced_from_the_wearer_landing_on_an_enemy() -> void:
	var wearer: Character = TestFactory.make_character()
	var relic: TheSealedDocketRelic = TheSealedDocketRelic.new()
	relic.Init(Types.Rarity.Legendary)
	wearer._trait = relic
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 100000
	enemy._current_health = 100000
	var plague: StatusEffects.Debuff = StatusEffects.Debuff.new()
	plague.type = Types.Debuff_Type.Plague
	plague.duration = 3
	plague.source_ID = 0
	plague.trait_riders[&"repeats_per_distinct_debuff"] = true
	plague.value = 100.0
	enemy._active_debuffs.append(plague)
	var enfeeble: StatusEffects.Debuff = StatusEffects.Debuff.new()
	enfeeble.type = Types.Debuff_Type.Enfeeble
	enfeeble.duration = 3
	enfeeble.source_ID = 0
	enemy._active_debuffs.append(enfeeble)
	var characters: Dictionary[int, Character] = {0: wearer, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	var health_before: int = enemy._current_health

	var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Debuff_Ticked)
	event.subject_ID = 1
	event.distinct_debuff_type_count = 2
	event.repeating_source_ids = [0]
	resolver._BeginBatch()
	resolver.GetCascadeResolver().Post(event)
	resolver._EndBatch()

	var unhalved_tick: int = int(floor(plague.value))
	assert_eq(health_before - enemy._current_health, int(floor(unhalved_tick * 0.5)),
		"A Comorbidity re-tick the wearer's own debuff sources must be halved even though " +
		"it lands on an enemy")

## Real end-to-end through a Herald whose own Weft and Warp self-bonus is a distinct
## mechanic key, so the two strength contributions must multiply rather than sum.
func test_stacks_multiplicatively_with_the_herald_self_bonus() -> void:
	var caster: Character = TestFactory.make_character()
	caster._current_health = 10
	caster._rarity = Types.Rarity.Rare
	var herald_trait: WeftAndWarpTrait = WeftAndWarpTrait.new()
	herald_trait.Init(Types.Rarity.Rare)
	caster._trait = herald_trait
	var relic: TheSealedDocketRelic = TheSealedDocketRelic.new()
	relic.Init(Types.Rarity.Legendary)
	_equip_relic(caster, Types.Slot.Weapon, relic)
	var skill: Skill = Skill.new()
	skill.name = "Cut the Cloth"
	skill.target = Types.Skill_Target.Single_Enemy
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 1.0}
	skill.effects = [damage]
	caster._skills = [skill]
	var enemy: Character = TestFactory.make_character()
	enemy._attributes[Types.Attribute.Health] = 1000
	enemy._current_health = 4000
	var characters: Dictionary[int, Character] = {0: caster, 1: enemy}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], [1]))
	resolver.BroadcastEvent(Types.Combat_Event.Start_Combat)
	herald_trait._tension = 1

	var results: Array[CombatResult] = resolver.ResolveSkill(0, [1], 0)
	var damage_results: Array[CombatResult] = results.filter(
			func(r: CombatResult) -> bool: return CombatResult.Kind.Damage == r.kind and 1 == r.target_ID)

	assert_eq(damage_results.size(), 2, "One base cast plus one Echo from 1 Tension")
	var buckets: Dictionary[StringName, float] = damage_results[1].combined_damage_modifier.Buckets()
	assert_almost_eq(buckets.get(&"TheSealedDocketRelic", 0.0), -0.5, 0.0001,
		"The Docket's drawback is its own bucket")
	assert_almost_eq(buckets.get(&"Weft and Warp", 0.0), WeftAndWarpTrait.SELF_BONUS_BY_RARITY[Types.Rarity.Rare],
		0.0001, "The Herald's self-bonus stays its own bucket, multiplying rather than summing")
