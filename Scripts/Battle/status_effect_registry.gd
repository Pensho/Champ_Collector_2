class_name StatusEffectRegistry extends Node

## Preload-based lookup from buff/debuff type to its StatusEffectData, mirroring the
## preloaded-Dictionary precedent in Scripts/Debug/debug_catalog.gd (DirAccess-based
## discovery is unsafe on Android export).

const BUFFS: Dictionary[Types.Buff_Type, StatusEffectData] = {
	Types.Buff_Type.Empower: preload("res://Data/Status_Effects/Empower.tres"),
	Types.Buff_Type.Fortify: preload("res://Data/Status_Effects/Fortify.tres"),
	Types.Buff_Type.Daunting_Strength: preload("res://Data/Status_Effects/Daunting_Strength.tres"),
	Types.Buff_Type.Phalanx_Guard: preload("res://Data/Status_Effects/Phalanx_Guard.tres"),
	Types.Buff_Type.Attune: preload("res://Data/Status_Effects/Attune.tres"),
	Types.Buff_Type.Haste: preload("res://Data/Status_Effects/Haste.tres"),
	Types.Buff_Type.True_Aim: preload("res://Data/Status_Effects/True_Aim.tres"),
	Types.Buff_Type.Clarity: preload("res://Data/Status_Effects/Clarity.tres"),
	Types.Buff_Type.Insight: preload("res://Data/Status_Effects/Insight.tres"),
	Types.Buff_Type.Vigor: preload("res://Data/Status_Effects/Vigor.tres"),
	Types.Buff_Type.Keen_Edge: preload("res://Data/Status_Effects/Keen_Edge.tres"),
	Types.Buff_Type.Lethal_Precision: preload("res://Data/Status_Effects/Lethal_Precision.tres"),
	Types.Buff_Type.Frenzy: preload("res://Data/Status_Effects/Frenzy.tres"),
	Types.Buff_Type.Opportunist: preload("res://Data/Status_Effects/Opportunist.tres"),
	Types.Buff_Type.Regeneration: preload("res://Data/Status_Effects/Regeneration.tres"),
	Types.Buff_Type.Exhert: preload("res://Data/Status_Effects/Exhert.tres"),
	Types.Buff_Type.Premonition: preload("res://Data/Status_Effects/Premonition.tres"),
	Types.Buff_Type.Deathward: preload("res://Data/Status_Effects/Deathward.tres"),
	Types.Buff_Type.Aegis: preload("res://Data/Status_Effects/Aegis.tres"),
	Types.Buff_Type.Mirror_Coat: preload("res://Data/Status_Effects/Mirror_Coat.tres"),
	Types.Buff_Type.Barrier: preload("res://Data/Status_Effects/Barrier.tres"),
	Types.Buff_Type.Luck: preload("res://Data/Status_Effects/Luck.tres"),
	Types.Buff_Type.Rehearsed: preload("res://Data/Status_Effects/Rehearsed.tres"),
	Types.Buff_Type.Overflow: preload("res://Data/Status_Effects/Overflow.tres"),
	Types.Buff_Type.Wanderlust: preload("res://Data/Status_Effects/Wanderlust.tres"),
	Types.Buff_Type.Steadfast: preload("res://Data/Status_Effects/Steadfast.tres"),
	Types.Buff_Type.Slipstream: preload("res://Data/Status_Effects/Slipstream.tres"),
	Types.Buff_Type.Resonance: preload("res://Data/Status_Effects/Resonance.tres"),
	Types.Buff_Type.Battle_Orders: preload("res://Data/Status_Effects/Battle_Orders.tres"),
	Types.Buff_Type.Rush: preload("res://Data/Status_Effects/Rush.tres"),
	Types.Buff_Type.Spotlight: preload("res://Data/Status_Effects/Spotlight.tres"),
	Types.Buff_Type.Catalyst: preload("res://Data/Status_Effects/Catalyst.tres"),
}

const DEBUFFS: Dictionary[Types.Debuff_Type, StatusEffectData] = {
	Types.Debuff_Type.Burning: preload("res://Data/Status_Effects/Burning.tres"),
	Types.Debuff_Type.Enfeeble: preload("res://Data/Status_Effects/Enfeeble.tres"),
	Types.Debuff_Type.Expose_Weakness: preload("res://Data/Status_Effects/Expose_Weakness.tres"),
	Types.Debuff_Type.Suppress: preload("res://Data/Status_Effects/Suppress.tres"),
	Types.Debuff_Type.Slow: preload("res://Data/Status_Effects/Slow.tres"),
	Types.Debuff_Type.Blind: preload("res://Data/Status_Effects/Blind.tres"),
	Types.Debuff_Type.Unravel: preload("res://Data/Status_Effects/Unravel.tres"),
	Types.Debuff_Type.Confound: preload("res://Data/Status_Effects/Confound.tres"),
	Types.Debuff_Type.Exposed_Facet: preload("res://Data/Status_Effects/Exposed_Facet.tres"),
	Types.Debuff_Type.Cracked_Facet: preload("res://Data/Status_Effects/Cracked_Facet.tres"),
	Types.Debuff_Type.Sequence_Lock: preload("res://Data/Status_Effects/Sequence_Lock.tres"),
	Types.Debuff_Type.Bleed: preload("res://Data/Status_Effects/Bleed.tres"),
	Types.Debuff_Type.Plague: preload("res://Data/Status_Effects/Plague.tres"),
	Types.Debuff_Type.Blight: preload("res://Data/Status_Effects/Blight.tres"),
	Types.Debuff_Type.Temporal_Leak: preload("res://Data/Status_Effects/Temporal_Leak.tres"),
	Types.Debuff_Type.Mana_Burn: preload("res://Data/Status_Effects/Mana_Burn.tres"),
	Types.Debuff_Type.Hexed: preload("res://Data/Status_Effects/Hexed.tres"),
	Types.Debuff_Type.Dead_Weight: preload("res://Data/Status_Effects/Dead_Weight.tres"),
	Types.Debuff_Type.Stun: preload("res://Data/Status_Effects/Stun.tres"),
	Types.Debuff_Type.Fatigue: preload("res://Data/Status_Effects/Fatigue.tres"),
	Types.Debuff_Type.Refracted: preload("res://Data/Status_Effects/Refracted.tres"),
	Types.Debuff_Type.Warped: preload("res://Data/Status_Effects/Warped.tres"),
	Types.Debuff_Type.Signed_Writ: preload("res://Data/Status_Effects/Signed_Writ.tres"),
	Types.Debuff_Type.Severance: preload("res://Data/Status_Effects/Severance.tres"),
	Types.Debuff_Type.Sanction: preload("res://Data/Status_Effects/Sanction.tres"),
	Types.Debuff_Type.Anchor: preload("res://Data/Status_Effects/Anchor.tres"),
}

static func BuffData(p_type: Types.Buff_Type) -> StatusEffectData:
	return BUFFS.get(p_type)

static func DebuffData(p_type: Types.Debuff_Type) -> StatusEffectData:
	return DEBUFFS.get(p_type)
