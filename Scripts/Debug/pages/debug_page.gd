class_name DebugPage extends Control

## Label shown on the debug overlay's tab for this page.
var page_title: String = "Page"

## Called by the debug overlay every time it is shown, so the page can
## re-read live game state before the developer sees it.
func Refresh() -> void:
	pass
