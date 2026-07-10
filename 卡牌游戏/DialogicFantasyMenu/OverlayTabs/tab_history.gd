extends OverlayUI_Tab

## A tab that displays the recent game history.

## Reference to a PackedScene that represents each "entry"
const HistoryItem := preload("res://DialogicFantasyMenu/OverlayTabs/history_message.tscn")


func _ready() -> void:
	super()


func _open() -> void:
	for child: Node in %HistoryList.get_children():
		child.queue_free()
