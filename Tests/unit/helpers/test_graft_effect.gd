class_name TestGraftEffect extends GraftEffect

## Headless stand-in for a concrete graft: a Health bonus percent that scales with
## rarity, a flat Speed drawback percent, and a Start_Combat hook applying a Buff so
## dispatch through Character._trait can be exercised without depending on the real
## graft pool content.
const HEALTH_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.10,
	Types.Rarity.Rare: 0.20,
	Types.Rarity.Epic: 0.30,
	Types.Rarity.Legendary: 0.40,
}
const SPEED_DRAWBACK: float = -0.05

var start_of_battle_called: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_title = "Test Graft"
	_body = "A test-only graft effect."
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	start_of_battle_called = true
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Fortify
	buff.duration = 1
	buff.name = "Fortify"
	p_resolver.GetStatusResolver().ApplyBuff(p_owner_ID, buff)

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Health: HEALTH_BONUS_PER_RARITY.get(p_rarity, 0.0)}

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Speed: SPEED_DRAWBACK}
