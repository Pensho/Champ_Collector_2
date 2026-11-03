class_name BattleMenu extends Control

## Covers the screen and swallows all input while open; the battle keeps running underneath.

signal status_list_requested
signal leave_confirmed

@export var _main_page: Control
@export var _status_page: Control
@export var _leave_page: Control
@export var _status_scroll: ScrollContainer
@export var _status_sections: Array[CharacterStatusSection]
@export var _no_statuses_label: Label

func Open() -> void:
	_ShowPage(_main_page)
	show()

func Close() -> void:
	hide()

func ShowStatuses(p_sections: Array[BattleStatusList.Section]) -> void:
	for index in _status_sections.size():
		if(index < p_sections.size()):
			_status_sections[index].SetSection(p_sections[index])
			_status_sections[index].show()
		else:
			_status_sections[index].hide()
	_no_statuses_label.visible = p_sections.is_empty()
	_status_scroll.scroll_vertical = 0
	_ShowPage(_status_page)

func _ShowPage(p_page: Control) -> void:
	for page: Control in [_main_page, _status_page, _leave_page]:
		page.visible = page == p_page

func _on_outside_button_up() -> void:
	Close()

func _on_return_button_up() -> void:
	Close()

func _on_statuses_button_up() -> void:
	status_list_requested.emit()

func _on_leave_button_up() -> void:
	_ShowPage(_leave_page)

func _on_back_button_up() -> void:
	_ShowPage(_main_page)

func _on_leave_confirm_button_up() -> void:
	Close()
	leave_confirmed.emit()
