class_name OvergrowthGraft extends GraftEffect

const REGENERATION_DURATION_PER_RARITY: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Uncommon: 1,
	Types.Rarity.Rare: 1,
	Types.Rarity.Epic: 2,
	Types.Rarity.Legendary: 2,
}

const HEAL_FRACTION_PER_STACK: float = 0.01
const STACKS_FOR_PAYOFF: int = 6

var _stacks: int = 0
var _regeneration_duration: int = 1
var _regeneration_buff: StatusEffects.Buff

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_regeneration_duration = REGENERATION_DURATION_PER_RARITY.get(p_rarity, 1)
	_title = "Overgrowth"
	_body = ("At the start of each of its turns, gains an Overgrowth stack and heals 1% of its"
			+ " max Health per stack held. At 6 stacks, every ally gains Regeneration for "
			+ str(_regeneration_duration) + " turn(s) and the stacks reset.")
	_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

	_regeneration_buff = StatusEffects.Buff.new()
	_regeneration_buff.type = Types.Buff_Type.Regeneration
	_regeneration_buff.name = "Regeneration"
	_regeneration_buff.duration = _regeneration_duration

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_stacks: String = (_body + "\n\n" +
			"Current Stacks: " + str(_stacks))
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_stacks, 0)

func StartOfTurn(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_stacks += 1
	p_resolver.ResolveTraitHeal([p_owner_ID], HEAL_FRACTION_PER_STACK * _stacks)

	if(_stacks >= STACKS_FOR_PAYOFF):
		var allies: Array[int] = p_resolver.GetSides().AlliesOf(p_owner_ID).AliveMembers(
				p_resolver.GetCharacters())
		for ally_ID in allies:
			p_resolver.GetStatusResolver().ApplyBuff(ally_ID, _regeneration_buff)
		_stacks = 0
