class_name SeaLegsZoneEffect extends SkillEffect

## The Gilded Deck's own on_trigger payload: grants the boarding character one stack of
## Sea Legs, sized on the *boarder's* own highest base primary attribute (Health excluded,
## the same list and tie order Field of Study already uses) rather than a fixed one, so the
## grant is worth something to every Role regardless of which attribute it leans on.

## Set by the Tidal Corsair trait from its own rarity table before the zone is placed -
## the per-stack rate is caster-specific data a data-only ZoneEffect resource can't carry.
var per_stack_rate: float = 0.0

func Resolve(p_context: SkillCastContext) -> void:
	for target_ID in p_context.TargetsFor(self):
		_Board(target_ID, p_context)

func _Board(p_target_ID: int, p_context: SkillCastContext) -> void:
	var target: Character = p_context.resolver.GetCharacters()[p_target_ID]
	var attribute: Types.Attribute = _HighestBasePrimaryAttribute(target)
	p_context.resolver.GetStatusResolver().ApplySeaLegs(
			p_target_ID, p_context.caster_ID, attribute, per_stack_rate * p_context.zone_magnitude)

func _HighestBasePrimaryAttribute(p_character: Character) -> Types.Attribute:
	var base_attributes: Dictionary[Types.Attribute, int] = p_character.GetBaseAttributes()
	var highest_value: int = -1
	var highest_attribute: Types.Attribute = FieldOfStudyTrait.PRIMARY_ATTRIBUTES[0]
	for attribute in FieldOfStudyTrait.PRIMARY_ATTRIBUTES:
		if(base_attributes[attribute] > highest_value):
			highest_value = base_attributes[attribute]
			highest_attribute = attribute
	return highest_attribute
