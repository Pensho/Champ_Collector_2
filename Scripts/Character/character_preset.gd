class_name CharacterPreset extends Resource

@warning_ignore_start("unused_private_class_variable")

@export var _name: String
@export var _texture: String
## Normalized (0-1) sub-rectangle of _texture drawn where a headshot is wanted.
@export var _headshot_region: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
@export var _normal_map: String
@export var _rarity: Types.Rarity
@export var _faction: Types.Faction
@export var _role: Types.Role
@export var _skills: Array[Skill]
@export var _thematic_hint: String = ""

# Default Attributes
@export var _health: int = 0
@export var _speed: int = 0
@export var _attack: int = 0
@export var _defence: int = 0
@export var _accuracy: int = 0
@export var _resistance: int = 0
@export var _mysticism: int = 0
@export var _knowledge: int = 0
@export var _critical_chance: int = Game_Balance.CHARACTER_BASE_CRIT_CH
@export var _critical_damage: int = Game_Balance.CHARACTER_BASE_CRIT_DMG

@export var _attribute_weight_types_available: Array[AttributeWeightPreset]

@export var _trait: CharacterTrait = null
@export var _graft_effect: GraftEffect = null

## Phase 2 kit, swapped in once at 50% Health: the full skill list, a trait that replaces
## the current one (null keeps it), and the combat text announcing the transition.
@export var _phase_two_skills: Array[Skill]
@export var _phase_two_trait: CharacterTrait = null
@export var _phase_two_text: String = ""

@export var _preset_path: String

@warning_ignore_restore("unused_private_class_variable")
