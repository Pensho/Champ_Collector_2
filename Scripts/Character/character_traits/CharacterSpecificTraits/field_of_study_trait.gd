class_name FieldOfStudyTrait extends CharacterTrait

## Shared with SeaLegsZoneEffect's own highest-base-primary-attribute pick (Role_Kit_
## Design.md 9.13) — kept here since it started here, though this trait no longer reads it.
const PRIMARY_ATTRIBUTES: Array[Types.Attribute] = [
	Types.Attribute.Attack,
	Types.Attribute.Defence,
	Types.Attribute.Accuracy,
	Types.Attribute.Resistance,
	Types.Attribute.Mysticism,
	Types.Attribute.Knowledge,
]

const AMPLIFICATION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.07,
	Types.Rarity.Rare: 0.08,
	Types.Rarity.Epic: 0.09,
	Types.Rarity.Legendary: 0.11,
}

var _amplification: float = 0.0

static func GetAmplification(p_rarity: Types.Rarity) -> float:
	return AMPLIFICATION.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_amplification = GetAmplification(p_rarity)
	_trait_texture = load(
			"res://Assets/Champ_Collector/Icons/Abilities/Passives/Field_Of_Study_Trait/field_of_study_trait.png")

	_title = "Field of Study"
	_body = ("Every attribute buff or debuff the team applies is " + str(_amplification * 100) \
			+ " percentage points stronger. Critical Chance and Critical Damage are unaffected.")

func GetAppliedAttributeAmplification() -> float:
	return _amplification

func GetConditionCount(
		_p_owner_ID: int,
		_p_target_ID: int,
		p_source: Types.Trait_Count_Source,
		p_resolver: BattleResolver) -> float:
	if(Types.Trait_Count_Source.Trait_Condition == p_source):
		return float(p_resolver.GetZoneResolver().GetZones().size())
	return 0.0
