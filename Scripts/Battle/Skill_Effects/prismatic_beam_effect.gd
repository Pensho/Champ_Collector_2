class_name PrismaticBeamEffect extends SkillEffect

## One Prismatic Rain beam: a random target, hit on the caster's own roll; a miss bends back into
## the caster while she holds Hexed and passes through her otherwise.

const PASSES_THROUGH_TEXT: String = "Passes through"
const BENT_BACK_TEXT: String = "Bent back"

@export var damage_scaling: Dictionary[Types.Attribute, float]
@export var hit_chance: float = 0.6

func Resolve(p_context: SkillCastContext) -> void:
	var targets: Array[int] = p_context.TargetsFor(self)
	if(targets.is_empty()):
		return
	var resolver: BattleResolver = p_context.resolver
	var target_ID: int = targets[resolver.GetRandom().randi_range(0, targets.size() - 1)]
	if(resolver.RollFavoring(p_context.caster_ID, 0.0, 1.0, false) < hit_chance):
		_Hit(p_context, target_ID)
	elif(_CasterIsHexed(p_context)):
		resolver.EmitTraitText(p_context.caster_ID, BENT_BACK_TEXT)
		_Hit(p_context, p_context.caster_ID)
	else:
		resolver.EmitTraitText(p_context.caster_ID, PASSES_THROUGH_TEXT)

func _Hit(p_context: SkillCastContext, p_target_ID: int) -> void:
	p_context.resolver.ResolveEffectDamage(p_context.caster_ID, p_target_ID, p_context.caster_attributes,
			damage_scaling, 1.0, CombinedDamageModifier.new())

func _CasterIsHexed(p_context: SkillCastContext) -> bool:
	var caster: Character = p_context.resolver.GetCharacters().get(p_context.caster_ID)
	return null != caster and caster._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Hexed == debuff.type)
