class_name FortunesFavorReveal extends Control

## Plays the Fortune's Favor reveal: panels slam in one by one, the center panel last; a
## champion win bursts every panel off screen to show the champion. A tap finishes early.

signal finished

enum Phase
{
	IDLE,
	SLAMMING,
	PRESENTING,
	WAITING_TO_CLOSE,
}

@export var _backdrop: ColorRect
## The center panel goes last.
@export var _panels: Array[FortunesFavorPanel]
@export var _champion_art: TextureRect
@export var _champion_name_label: Label
@export var _champion_rarity_label: Label
@export var _flash: ColorRect
@export var _burst_motes: CPUParticles2D
@export var _tease_texture: Texture2D
@export var _neutral_glow_color: Color
@export var _slam_interval: float
@export var _slam_duration: float
@export var _tease_hold: float
@export var _burst_duration: float
@export var _burst_distance: float
@export var _flash_duration: float
## Space between the champion art and the name above it and the rarity below it.
@export var _name_label_gap: float
@export var _name_fade_duration: float

var _phase: Phase = Phase.IDLE
var _skip_requested: bool = false

func _ready() -> void:
	hide()

func Play(p_tier: FortuneFavorTier, p_rewards: Array[Dictionary]) -> void:
	var entries: Array[Dictionary] = FortunesFavorRevealLayout.AssignRewardsToPanels(p_rewards, _panels.size())
	var champion_entry: Dictionary = entries[entries.size() - 1]
	var won_champion: bool = FortunesFavorRevealLayout.IsChampion(champion_entry)
	var filler_textures: Array[Texture2D] = p_tier.empty_textures.duplicate()
	filler_textures.shuffle()
	var filler_count: int = 0
	for index in _panels.size():
		var filler_texture: Texture2D = null
		if(entries[index].is_empty() and not filler_textures.is_empty()):
			filler_texture = filler_textures[filler_count % filler_textures.size()]
			filler_count += 1
		_PreparePanel(_panels[index], entries[index], p_tier, filler_texture)
	_champion_art.hide()
	_champion_name_label.hide()
	_champion_rarity_label.hide()
	_flash.modulate.a = 0.0
	_skip_requested = false
	_backdrop.show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()

	_phase = Phase.SLAMMING
	var slammed_count: int = 0
	while(slammed_count < _panels.size() and not _skip_requested):
		if(slammed_count > 0):
			_panels[slammed_count - 1].Dim(_slam_duration)
		_panels[slammed_count].SlamIn(_slam_duration)
		slammed_count += 1
		await _WaitUnlessSkipped(_slam_interval)
	if(slammed_count < _panels.size()):
		for index in _panels.size():
			_panels[index].SnapToRest()
			if(index < _panels.size() - 1):
				_panels[index].Dim(_slam_duration)
		_panels[_panels.size() - 1].SlamIn(_slam_duration)

	if(won_champion):
		_phase = Phase.PRESENTING
		await get_tree().create_timer(_tease_hold).timeout
		_Burst(champion_entry)
		await get_tree().create_timer(_burst_duration).timeout

	_phase = Phase.WAITING_TO_CLOSE

func _gui_input(p_event: InputEvent) -> void:
	var tapped: bool = (p_event is InputEventMouseButton and p_event.pressed) \
			or (p_event is InputEventScreenTouch and p_event.pressed)
	if(not tapped):
		return
	accept_event()
	match _phase:
		Phase.SLAMMING:
			_skip_requested = true
		Phase.WAITING_TO_CLOSE:
			_phase = Phase.IDLE
			_Close()
			finished.emit()

## A won champion and its labels stay on screen, letting clicks through, until the next Play or scene change.
func _Close() -> void:
	if(not _champion_art.visible):
		hide()
		return
	_backdrop.hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _PreparePanel(
		p_panel: FortunesFavorPanel, p_entry: Dictionary, p_tier: FortuneFavorTier, p_filler_texture: Texture2D) -> void:
	var texture: Texture2D = p_filler_texture
	var reward_particles: PackedScene = null
	if(not p_entry.is_empty()):
		match p_entry["type"]:
			RecruitmentManager.RewardType.CHAMPION:
				texture = _tease_texture
			RecruitmentManager.RewardType.SILVER:
				texture = p_tier.silver_texture
				reward_particles = p_tier.silver_particles
			RecruitmentManager.RewardType.SUPPLIES:
				texture = p_tier.supplies_texture
				reward_particles = p_tier.supplies_particles
	p_panel.ResetHidden()
	p_panel.SetEntry(texture, FortunesFavorRevealLayout.GlowColor(p_entry, _neutral_glow_color), reward_particles)

func _Burst(p_champion_entry: Dictionary) -> void:
	var champion: CharacterPreset = p_champion_entry["champion"]
	var rarity_color: Color = FortunesFavorRevealLayout.GlowColor(p_champion_entry, _neutral_glow_color)
	_champion_art.texture = load(champion._texture)
	_champion_art.show()
	_ShowChampionLabels(champion, _champion_art.texture.get_size().y, rarity_color)

	_flash.color = rarity_color
	_flash.modulate.a = 1.0
	create_tween().tween_property(_flash, "modulate:a", 0.0, _flash_duration)
	_burst_motes.color = rarity_color
	_burst_motes.restart()

	var screen_center: Vector2 = get_viewport_rect().size * 0.5
	var center_index: int = _panels.size() - 1
	for index in _panels.size():
		var direction: Vector2 = Vector2.ZERO
		if(index != center_index):
			direction = FortunesFavorRevealLayout.BurstDirection(_panels[index].OutlineCenter(), screen_center)
		_panels[index].BurstOut(direction, _burst_distance, _burst_duration)

func _ShowChampionLabels(p_champion: CharacterPreset, p_art_height: float, p_rarity_color: Color) -> void:
	var screen_height: float = get_viewport_rect().size.y
	var art_top: float = _champion_art.position.y + (_champion_art.size.y - p_art_height) * 0.5
	var art_bottom: float = art_top + p_art_height

	_champion_name_label.text = p_champion._name
	_champion_name_label.position.y = maxf(
			art_top - _name_label_gap - _champion_name_label.size.y, _name_label_gap)
	_champion_rarity_label.text = Types.RarityName(p_champion._rarity)
	_champion_rarity_label.add_theme_color_override("font_color", p_rarity_color)
	_champion_rarity_label.position.y = minf(
			art_bottom + _name_label_gap, screen_height - _name_label_gap - _champion_rarity_label.size.y)

	for label: Label in [_champion_name_label, _champion_rarity_label]:
		label.modulate.a = 0.0
		label.show()
		create_tween().tween_property(label, "modulate:a", 1.0, _name_fade_duration)

func _WaitUnlessSkipped(p_seconds: float) -> void:
	var elapsed: float = 0.0
	while(elapsed < p_seconds and not _skip_requested):
		await get_tree().process_frame
		elapsed += get_process_delta_time()
