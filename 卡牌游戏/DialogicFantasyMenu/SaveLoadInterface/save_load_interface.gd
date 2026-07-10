extends VBoxContainer

## Script that manages saving and loading and displaying save slots.
## This is used by the save and the load tab.

signal loaded
signal saved
signal page_changed(page_index:int)

var slots_per_page := 4
@export var time_string := "{day}/{month}/{year} | {hour}:{minute}"

enum Modes {SAVE, LOAD}
@export var mode := Modes.SAVE
@export var WarningDialog: Control = null

var page_index := 0


func _ready() -> void:
	$SlotPageButtons/Page1.button_group.pressed.connect(_on_page_selected)
	for slot in $Slots.get_children():
		slot.selected.connect(_on_slot_button_selected.bind(slot.get_index()))
		slot.time_string = time_string
		slot.delete_request.connect(_on_slot_delete_request.bind(slot.get_index()))

	load_page(0)


func _on_page_selected(button: Button) -> void:
	load_page(button.get_index())
	page_changed.emit(button.get_index())


func load_page(new_page_index := page_index) -> void:
	page_index = new_page_index

	for i in $Slots.get_children():
		i.clear()

	$SlotPageButtons.get_child(page_index).button_pressed = true


func _on_slot_button_selected(button_index: int) -> void:
	var slot_name := get_slot_name(button_index)

	if mode == Modes.SAVE:
		save_to_slot(slot_name)

	elif mode == Modes.LOAD:
		if find_parent("OverlayUI").has_just_saved:
			load_slot(slot_name)
		else:
			WarningDialog.warn("Unsaved progress will be lost.",
				[
					{"text":"Load", "action":load_slot.bind(slot_name)}
				])


func save_to_slot(_slot_name:String) -> void:
	saved.emit()


func load_slot(_slot_name:String) -> void:
	loaded.emit()


func _on_slot_delete_request(button_index: int) -> void:
	if WarningDialog:
		WarningDialog.warn("Are you sure you want to delete this slot?",
			[
				{"text":"Yes", "action":delete_slot.bind(get_slot_name(button_index))},
				{"text":"No"}
			], false)


func delete_slot(_slot_name:String) -> void:
	load_page(page_index)


func get_slot_name(button_index: int) -> String:
	return "slot_"+str(page_index * slots_per_page + button_index)
