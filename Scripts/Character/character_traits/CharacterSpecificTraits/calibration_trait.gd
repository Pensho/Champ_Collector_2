class_name CalibrationTrait extends CharacterTrait

const MAX_CHARGES: int = 10
const EXPOSE_WEAKNESS_THRESHOLD: int = 4
const EXPOSE_WEAKNESS_DURATION: int = 2
const ZONE_RE_ERECT_THRESHOLD: int = 7
const ZONE_UPGRADE_CHARGES: int = 8
const RAISE_THE_FRAME_ZONE_CHARGES: int = 5
const RAISE_THE_FRAME_CONSUME_CAP: int = 3

const PER_CHARGE_POTENCY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.04,
	Types.Rarity.Rare: 0.06,
	Types.Rarity.Epic: 0.08,
	Types.Rarity.Legendary: 0.10,
}

var _charges: int = 0
var _per_charge_potency: float = 0.0
var _expose_weakness_debuff: StatusEffects.Debuff
var _charges_invested_per_zone: Dictionary[int, int] = {}

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_per_charge_potency = PER_CHARGE_POTENCY.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Status_Effects/Barrier/Barrier.png")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Zone_Used] = Callable(self, "OnZoneUsed")
	_execution_steps[Types.Combat_Event.Zone_Constructed] = Callable(self, "OnZoneConstructed")

	_expose_weakness_debuff = StatusEffects.Debuff.new()
	_expose_weakness_debuff.type = Types.Debuff_Type.Expose_Weakness
	_expose_weakness_debuff.duration = EXPOSE_WEAKNESS_DURATION
	_expose_weakness_debuff.name = "Expose Weakness"

	_title = "Calibration"
	_body = ("Gain Calibration charges with basic skills and spend them with others for effects." +
			"\n\nFinisher skills consume all held charges for " +
			str(int(round(100.0 * _per_charge_potency))) + "% bonus damage per charge, beyond their own effects.")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_charges = 0
	_charges_invested_per_zone.clear()

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_charges: String = (_body + "\n\n" +
			"Current Charges: " + str(_charges))
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_charges, 0)

func OnZoneUsed(_p_owner_ID: int, _p_user_ID: int, _p_resolver: BattleResolver) -> void:
	_charges = min(_charges + 1, MAX_CHARGES)

func OnSkillCast(
		_p_owner_ID: int,
		p_target_IDs: Array[int],
		p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var skill_result: TraitSkillResult = TraitSkillResult.new()
	match p_skill_name:
		"Cornerstone":
			_charges = min(_charges + 1, MAX_CHARGES)
		"Raise the Frame":
			_charges -= min(_charges, RAISE_THE_FRAME_CONSUME_CAP)
		"Final Calculation":
			skill_result._damage_multiplier += _per_charge_potency * _charges
			if(_charges >= EXPOSE_WEAKNESS_THRESHOLD):
				_expose_weakness_debuff.source_ID = _p_owner_ID
				for target_ID in p_target_IDs:
					p_resolver.ApplyDebuff(target_ID, _expose_weakness_debuff)
			if(_charges >= ZONE_RE_ERECT_THRESHOLD):
				_ReErectZone(_p_owner_ID, p_resolver)
			_charges = 0

	return skill_result

func OnZoneConstructed(_p_owner_ID: int, p_zone_ID: int, p_resolver: BattleResolver) -> void:
	var zone: Zone = p_resolver.GetZones().get(p_zone_ID)
	if(null == zone or Types.Skill_Type.Barrier_Zone != zone._type):
		return
	_charges_invested_per_zone[p_zone_ID] = min(_charges, RAISE_THE_FRAME_CONSUME_CAP)

func GetZoneChargeBonus(p_zone_ID: int) -> float:
	return _charges_invested_per_zone.get(p_zone_ID, 0) * _per_charge_potency

func _ReErectZone(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	var zones: Dictionary[int, Zone] = p_resolver.GetZones()
	for zone_ID: int in zones:
		if(zones[zone_ID]._owner_ID == p_owner_ID):
			zones[zone_ID]._duration = ZONE_UPGRADE_CHARGES
			return

	var available_zone_IDs: Array[int] = p_resolver.AvailableZoneIDs()
	if(available_zone_IDs.is_empty()):
		return

	var zone_skill: Skill = Skill.new()
	zone_skill.name = "Raise the Frame"
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Barrier_Zone
	zone_skill.duration = RAISE_THE_FRAME_ZONE_CHARGES
	p_resolver.PlaceZone(available_zone_IDs[0], p_owner_ID, zone_skill)
