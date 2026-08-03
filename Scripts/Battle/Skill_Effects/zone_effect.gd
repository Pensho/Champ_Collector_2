class_name ZoneEffect extends SkillEffect

enum Section { Player_Chosen, Left_Most_Empty, Random_Empty }

@export var charges: int = 0
@export var section: Section = Section.Player_Chosen
@export var on_trigger: Array[SkillEffect] = []
@export var visual_scene: PackedScene

func Resolve(p_context: SkillCastContext) -> void:
	var zone_resolver: ZoneResolver = p_context.resolver.GetZoneResolver()
	var zone_ID: int = _ResolveSection(p_context, zone_resolver)
	if(-1 == zone_ID or zone_resolver.HasZone(zone_ID)):
		return
	var effective_target: Types.Skill_Target = (
			p_context.skill.target if Types.Skill_Target.Skill_Default == target else target)
	var placing_skill_name: String = p_context.skill.name if null != p_context.skill else ""
	zone_resolver.PlaceZone(zone_ID, p_context.caster_ID, self, effective_target,
			p_context.resolver.GetEffectiveAttributes(p_context.caster_ID), placing_skill_name)

func _ResolveSection(p_context: SkillCastContext, p_zone_resolver: ZoneResolver) -> int:
	var available: Array[int] = p_zone_resolver.AvailableZoneIDs()
	match section:
		Section.Left_Most_Empty:
			return available[0] if not available.is_empty() else -1
		Section.Random_Empty:
			return _RandomFrom(available, p_context)
		_:
			var pending: int = p_context.resolver.ConsumePendingZoneSection()
			# A player made no choice (an enemy cast this skill) — fall back to a random
			# free section, matching how enemy AI always picked before this was data-driven.
			return pending if -1 != pending else _RandomFrom(available, p_context)

func _RandomFrom(p_available: Array[int], p_context: SkillCastContext) -> int:
	if(p_available.is_empty()):
		return -1
	return p_available[p_context.resolver.GetRandom().randi_range(0, p_available.size() - 1)]
