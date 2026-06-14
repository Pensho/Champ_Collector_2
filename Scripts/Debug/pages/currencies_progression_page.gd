extends DebugPage

@export var _silver_spin: SpinBox
@export var _supplies_spin: SpinBox
@export var _fortunes_favor_bone_spin: SpinBox
@export var _fortunes_favor_brass_spin: SpinBox
@export var _fortunes_favor_parchment_spin: SpinBox
@export var _encounter_id_edit: LineEdit
@export var _difficulty_spin: SpinBox
@export var _encounters_label: Label

func _ready() -> void:
	page_title = "Currencies & Progression"
	_supplies_spin.max_value = Game_Balance.MAX_SUPPLIES
	_difficulty_spin.min_value = 1
	_difficulty_spin.max_value = Game_Balance.MAX_DIFFICULTY

func Refresh() -> void:
	var resources: ResourceHandler = main.GetInstance()._resources
	_silver_spin.value = resources._silver
	_supplies_spin.value = resources._supplies
	_fortunes_favor_bone_spin.value = resources.GetFortunesFavor(FortuneFavorTier.TierType.BONE)
	_fortunes_favor_brass_spin.value = resources.GetFortunesFavor(FortuneFavorTier.TierType.BRASS)
	_fortunes_favor_parchment_spin.value = resources.GetFortunesFavor(FortuneFavorTier.TierType.PARCHMENT)
	RefreshEncounterList()

func RefreshEncounterList() -> void:
	var progress: ProgressHandler = main.GetInstance()._progress
	var lines: Array[String] = []
	for encounter_id in progress._stage_difficulty.keys():
		lines.append(encounter_id + ": " + str(progress._stage_difficulty[encounter_id]))
	if(lines.is_empty()):
		_encounters_label.text = "No encounters registered yet."
	else:
		_encounters_label.text = "\n".join(lines)

func _on_apply_currencies_button_up() -> void:
	var resources: ResourceHandler = main.GetInstance()._resources
	resources._silver = int(_silver_spin.value)
	resources._supplies = int(_supplies_spin.value)
	resources._fortunes_favor[FortuneFavorTier.TierType.BONE] = int(_fortunes_favor_bone_spin.value)
	resources._fortunes_favor[FortuneFavorTier.TierType.BRASS] = int(_fortunes_favor_brass_spin.value)
	resources._fortunes_favor[FortuneFavorTier.TierType.PARCHMENT] = int(_fortunes_favor_parchment_spin.value)

func _on_set_difficulty_button_up() -> void:
	var encounter_id: String = _encounter_id_edit.text.strip_edges()
	if(encounter_id.is_empty()):
		return
	var progress: ProgressHandler = main.GetInstance()._progress
	progress.RegisterEncounter(encounter_id)
	progress._stage_difficulty[encounter_id] = int(_difficulty_spin.value)
	RefreshEncounterList()
