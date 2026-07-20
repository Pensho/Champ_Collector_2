class_name StrikeTheFlawTrait extends CharacterTrait

const CRACKED_FACET_DURATION: Dictionary[Types.Rarity, int] = {
	Types.Rarity.Uncommon: 1,
	Types.Rarity.Rare: 1,
	Types.Rarity.Epic: 2,
	Types.Rarity.Legendary: 2,
}

var _cracked_facet_debuff: StatusEffects.Debuff

static func GetCrackedFacetDuration(p_rarity: Types.Rarity) -> int:
	return CRACKED_FACET_DURATION.get(p_rarity, 0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Status_Effects/Cracked_Facet/Cracked_Facet.png")
	_execution_steps[Types.Combat_Event.Critical_Hit] = Callable(self, "OnCriticalHit")

	_cracked_facet_debuff = StatusEffects.Debuff.new()
	_cracked_facet_debuff.type = Types.Debuff_Type.Cracked_Facet
	_cracked_facet_debuff.duration = GetCrackedFacetDuration(p_rarity)
	_cracked_facet_debuff.name = "Cracked Facet"

	_title = "Strike the Flaw"
	_body = "Critical hits apply Cracked Facet to the target."

func OnCriticalHit(p_owner_ID: int, p_target_ID: int, p_resolver: BattleResolver) -> void:
	_cracked_facet_debuff.source_ID = p_owner_ID
	p_resolver.ApplyDebuff(p_target_ID, _cracked_facet_debuff)
