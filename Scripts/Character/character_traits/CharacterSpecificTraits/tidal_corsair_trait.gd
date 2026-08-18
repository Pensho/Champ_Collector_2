class_name TidalCorsairTrait extends CharacterTrait

enum Stack_Type
{
	Empty,
	Steel,
	Sea,
}

const MAX_STACKS: int = 3
const GILDED_DECK_VISUAL_SCENE: PackedScene = preload(
		"res://Scenes/ui/Turn_Bar_Zones/Turn_Bar_Gilded_Deck.tscn")
const CHARGES_PER_SEA_PURE: int = 2
const CHARGES_PER_SEA_MIXED: int = 1
const MIXED_HAND_CHARGE_CAP: int = 2
const CREW_BUFF_DURATION: int = 2

const DAMAGE_PER_STEEL_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.45,
	Types.Rarity.Rare: 0.50,
	Types.Rarity.Epic: 0.55,
	Types.Rarity.Legendary: 0.60,
}

const SEA_LEGS_RATE_PER_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.05,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.07,
	Types.Rarity.Legendary: 0.08,
}

class StackDescription:
	var _title: String = "Title"
	var _body: String = "Body"

var _sea_stack_texture: Texture2D
var _steel_stack_texture: Texture2D
var _held_stacks: Array[Stack_Type]
var _steel_description: StackDescription
var _sea_description: StackDescription
var _blank_description: StackDescription
var _damage_per_steel_stack: float = 0.0
var _sea_legs_rate_per_stack: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_damage_per_steel_stack = DAMAGE_PER_STEEL_STACK.get(p_rarity, 0.0)
	_sea_legs_rate_per_stack = SEA_LEGS_RATE_PER_STACK.get(p_rarity, 0.0)
	_held_stacks = [Stack_Type.Empty, Stack_Type.Empty, Stack_Type.Empty]
	_sea_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Sea.png")
	_steel_stack_texture = load("res://Assets/Champ_Collector/Creatures/Tidal_Corsair/Tidal_Corsair_Stack_Steel.png")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_steel_description = StackDescription.new()
	_steel_description._title = "Steel Stack"
	_steel_description._body = ("On a Steel-only Corsair's Reckoning, adds +" +
			str(roundi(100.0 * _damage_per_steel_stack)) + "% damage per Steel stack.")

	_sea_description = StackDescription.new()
	_sea_description._title = "Sea Stack"
	_sea_description._body = "Consumed by Corsair's Reckoning to raise or resupply The Gilded Deck."

	_blank_description = StackDescription.new()
	_blank_description._title = "Empty Stack"
	_blank_description._body = "Use an ability that grants stacks to fill this slot."

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_held_stacks = [Stack_Type.Empty, Stack_Type.Empty, Stack_Type.Empty]

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	for i in _held_stacks.size():
		match _held_stacks[i]:
			Stack_Type.Steel:
				p_character_repr.SetTraitElement(_steel_stack_texture, i)
				p_character_repr.SetTraitElementToolTip(_steel_description._title, _steel_description._body, i)
			Stack_Type.Sea:
				p_character_repr.SetTraitElement(_sea_stack_texture, i)
				p_character_repr.SetTraitElementToolTip(_sea_description._title, _sea_description._body, i)
			Stack_Type.Empty:
				p_character_repr.SetBlankTraitElement(i)
				p_character_repr.SetTraitElementToolTip(_blank_description._title, _blank_description._body, i)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var skill_result: TraitSkillResult = TraitSkillResult.new()
	match p_skill_name:
		"Boarding Strike":
			for i in _held_stacks.size():
				if(_held_stacks[i] == Stack_Type.Empty):
					_held_stacks[i] = Stack_Type.Steel
					break;
		"Saltwater Shot":
			for i in _held_stacks.size():
				if(_held_stacks[i] == Stack_Type.Empty):
					_held_stacks[i] = Stack_Type.Sea
					break;
		"Corsairs Reckoning":
			_ResolveReckoning(p_owner_ID, p_resolver, skill_result)

	return skill_result

func _ResolveReckoning(
		p_owner_ID: int, p_resolver: BattleResolver, p_skill_result: TraitSkillResult) -> void:
	var steel_count: int = 0
	var sea_count: int = 0
	for stack in _held_stacks:
		if(Stack_Type.Steel == stack):
			steel_count += 1
		elif(Stack_Type.Sea == stack):
			sea_count += 1
	_held_stacks = [Stack_Type.Empty, Stack_Type.Empty, Stack_Type.Empty]

	if(0 == sea_count):
		p_skill_result._damage_multiplier += steel_count * _damage_per_steel_stack
	elif(0 == steel_count):
		_RaiseOrResupplyDeck(p_owner_ID, sea_count * CHARGES_PER_SEA_PURE, p_resolver)
	else:
		_RaiseOrResupplyDeck(
				p_owner_ID, mini(sea_count * CHARGES_PER_SEA_MIXED, MIXED_HAND_CHARGE_CAP), p_resolver)
		_GrantCrewBuffs(p_owner_ID, p_resolver)

func _RaiseOrResupplyDeck(p_owner_ID: int, p_charges: int, p_resolver: BattleResolver) -> void:
	if(p_charges <= 0):
		return
	var zone_resolver: ZoneResolver = p_resolver.GetZoneResolver()
	var zones: Dictionary[int, Zone] = zone_resolver.GetZones()
	for zone_ID: int in zones:
		if(zones[zone_ID]._owner_ID == p_owner_ID):
			zone_resolver.SetZoneCharges(zone_ID, zones[zone_ID]._charges + p_charges)
			return

	var zone_ID: int = zone_resolver.SectionWithMostAllies(p_owner_ID)
	if(-1 == zone_ID):
		return
	var sea_legs_effect: SeaLegsZoneEffect = SeaLegsZoneEffect.new()
	sea_legs_effect.per_stack_rate = _sea_legs_rate_per_stack
	var zone_effect: ZoneEffect = ZoneEffect.new()
	zone_effect.charges = p_charges
	zone_effect.on_trigger = [sea_legs_effect]
	zone_effect.visual_scene = GILDED_DECK_VISUAL_SCENE
	zone_resolver.PlaceZone(zone_ID, p_owner_ID, zone_effect, Types.Skill_Target.ZoneAlly,
			p_resolver.GetEffectiveAttributes(p_owner_ID), "The Gilded Deck")

func _GrantCrewBuffs(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	var status_resolver: StatusEffectResolver = p_resolver.GetStatusResolver()
	for ally_ID in allies:
		if(p_owner_ID == ally_ID):
			continue
		var slipstream: StatusEffects.Buff = StatusEffects.Buff.new()
		slipstream.type = Types.Buff_Type.Slipstream
		slipstream.duration = CREW_BUFF_DURATION
		slipstream.name = "Slipstream"
		slipstream.source_ID = p_owner_ID
		status_resolver.ApplyBuff(ally_ID, slipstream)

		var empower: StatusEffects.Buff = StatusEffects.Buff.new()
		empower.type = Types.Buff_Type.Empower
		empower.duration = CREW_BUFF_DURATION
		empower.name = "Empower"
		empower.source_ID = p_owner_ID
		status_resolver.ApplyBuff(ally_ID, empower)
