class_name TheUnguardedGlassRelic extends RelicEffect

var _owner_ID: int = -1
var _resolver: BattleResolver = null

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Unguarded_Glass/The_Unguarded_Glass.png")
	_title = "The Unguarded Glass"
	_magnitude_by_rarity = [0.35, 0.45, 0.55, 0.70, 0.80]
	_body = ("While the wearer holds a buff granted by an ally, critical hits deal +" +
			str(roundi(Magnitude() * 100)) + "% Critical Damage.\n" +
			"The wearer can hold at most one buff at a time; a new buff replaces " +
			"the one they hold.")
	_execution_steps[Types.Combat_Event.Buff_Applied] = Callable(self, "OnBuffGained")

func OnBuffGained(p_owner_ID: int, p_buff: StatusEffects.Buff, p_resolver: BattleResolver) -> void:
	_owner_ID = p_owner_ID
	_resolver = p_resolver
	var owner: Character = p_resolver.GetCharacters().get(p_owner_ID)
	if(null == owner):
		return
	for existing: StatusEffects.Buff in owner._active_buffs.duplicate():
		if(existing != p_buff):
			p_resolver.GetStatusResolver().RemoveBuff(p_owner_ID, existing)

func GetAttributeDelta(p_attribute: Types.Attribute, p_base_value: int) -> int:
	if(Types.Attribute.CritDamage != p_attribute or -1 == _owner_ID):
		return 0
	var owner: Character = _resolver.GetCharacters().get(_owner_ID)
	if(null == owner):
		return 0
	for buff: StatusEffects.Buff in owner._active_buffs:
		if(buff.source_ID != _owner_ID and buff.source_ID >= 0
				and _resolver.GetSides().AreAllies(buff.source_ID, _owner_ID)):
			return int(ceilf(p_base_value * Magnitude()))
	return 0
