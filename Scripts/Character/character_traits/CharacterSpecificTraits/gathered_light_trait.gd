class_name GatheredLightTrait extends CharacterTrait

## Gathered Light (Encounter_Design_Document.md 2.2), on the Hue-Eater and the Gatherers: a shape
## gains one part at the start of each of the owner's turns. A full shape hovers for a turn, then
## flies onto the owner's enemies at the start of the next and resets. Each Enfeeble landing on
## the owner is consumed and breaks parts off. Subclasses supply the shape's scenes.

const LAUNCH_TEXT: String = "Gathered Light"

@export var _starting_parts: int = 0
@export var _parts_to_complete: int = 0
@export var _parts_per_enfeeble: int = 0
@export var _launch_damage_scaling: Dictionary[Types.Attribute, float] = {}

var _parts: int = 0
var _owner: WeakRef = null

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_parts = _starting_parts
	_effect_archetypes = [_LaunchScene()]
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")
	_execution_steps[Types.Combat_Event.Debuff_Received] = Callable(self, "OnDebuffReceived")

func ResetForBattle() -> void:
	_parts = _starting_parts

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_owner = weakref(p_resolver.GetCharacters().get(p_owner_ID))

func GetParts() -> int:
	return _parts

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	if(_parts < _parts_to_complete):
		_parts += 1
		return
	_parts = 0
	p_resolver.EmitTraitText(p_owner_ID, LAUNCH_TEXT)
	var enemy_IDs: Array[int] = p_resolver.GetSides().EnemiesOf(p_owner_ID).AliveMembers(p_resolver.GetCharacters())
	if(not enemy_IDs.is_empty()):
		p_resolver.EmitTraitEffect(p_owner_ID, enemy_IDs[0], _LaunchScene())
	p_resolver.ResolveTraitDamage(p_owner_ID, enemy_IDs, p_resolver.GetEffectiveAttributes(p_owner_ID),
			_launch_damage_scaling, false)

func OnDebuffReceived(p_owner_ID: int, p_debuff: StatusEffects.Debuff, p_resolver: BattleResolver) -> void:
	if(Types.Debuff_Type.Enfeeble != p_debuff.type):
		return
	p_resolver.GetStatusResolver().RemoveDebuff(p_owner_ID, p_debuff)
	_parts = maxi(0, _parts - _parts_per_enfeeble)

## The scene of a full shape flying at the party.
func _LaunchScene() -> PackedScene:
	return null

func _Owner() -> Character:
	return _owner.get_ref() if null != _owner else null

func _OwnerAlive() -> bool:
	var owner: Character = _Owner()
	return null != owner and owner._current_health > 0
