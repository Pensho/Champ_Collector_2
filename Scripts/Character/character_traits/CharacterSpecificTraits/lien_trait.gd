class_name LienTrait extends CharacterTrait

const EMPOWER_DURATION: int = 2
const TURN_COOLDOWN: int = 4

var _turns_since_trigger: int = TURN_COOLDOWN

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load(
		"res://Assets/Champ_Collector/Icons/Abilities/Passives/Lien/Lien.png"
	)
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

	_title = "Lien"
	_body = "At the start of the user's turn, if they hold no buffs, they gain" \
			+ " Empower for 2 turns. Triggers at most once every 4 turns."

func RefreshVisuals(_p_character_repr: CharacterRepresentation) -> void:
	pass

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_turns_since_trigger = TURN_COOLDOWN

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_turns_since_trigger += 1
	if(_turns_since_trigger < TURN_COOLDOWN):
		return
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]
	if(not owner._active_buffs.is_empty()):
		return
	var empower: StatusEffects.Buff = StatusEffects.Buff.new()
	empower.type = Types.Buff_Type.Empower
	empower.duration = EMPOWER_DURATION
	empower.name = "Empower"
	p_resolver.GetStatusResolver().ApplyBuff(p_owner_ID, empower)
	_turns_since_trigger = 0
