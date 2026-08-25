class_name NotificationHandler extends CanvasLayer

const NOTIFICATION_BOX_SCENE: PackedScene = preload("res://Scenes/ui/General_UI/Notification_Box.tscn")
const MAX_QUEUE_LENGTH: int = 5

var _queue: Array[Dictionary] = []
var _active: NotificationBox

func _ready() -> void:
	layer = 64

func Notify(p_text: String, p_kind: Types.Notification_Kind = Types.Notification_Kind.Info) -> void:
	_queue.append({"text": p_text, "kind": p_kind})
	if(_queue.size() > MAX_QUEUE_LENGTH):
		_queue.pop_front()
	if(not _active):
		_show_next()

func _show_next() -> void:
	if(_queue.is_empty()):
		return

	var entry: Dictionary = _queue.pop_front()
	var box: NotificationBox = NOTIFICATION_BOX_SCENE.instantiate()
	add_child(box)
	box.SetValue(entry["text"], entry["kind"])
	box.position = (get_viewport().get_visible_rect().size * 0.5) - (box.GetSize() * 0.5)
	box.finished.connect(_on_notification_finished)
	_active = box
	box.Animate()

func _on_notification_finished() -> void:
	if(_active):
		_active.queue_free()
	_active = null
	_show_next()
