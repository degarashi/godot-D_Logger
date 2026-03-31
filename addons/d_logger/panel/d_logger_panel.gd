@tool
extends Control

# ------------- [Private Variable] -------------
var _all_logs: Array[Dictionary] = []
# category (String) -> is_active (bool)
var _active_filters: Dictionary[String, bool] = {}

@onready var clear_button: Button = %ClearButton
@onready var log_display: RichTextLabel = %RichTextLabel
@onready var filter_container: HBoxContainer = %FilterContainer


# ------------- [Callbacks] -------------
func _ready() -> void:
	clear_button.pressed.connect(_on_clear_pressed)
	log_display.bbcode_enabled = true
	# enable automatic scrolling
	log_display.scroll_following = true


# ------------- [Private Method] -------------
func _add_filter_button(category: String) -> void:
	_active_filters[category] = true
	var btn := Button.new()
	btn.text = category
	btn.toggle_mode = true
	btn.button_pressed = true
	btn.toggled.connect(_on_filter_toggled.bind(category))
	filter_container.add_child(btn)


func _on_filter_toggled(is_pressed: bool, category: String) -> void:
	_active_filters[category] = is_pressed
	_rebuild_log_display()


func _append_formatted_log(log_data: Dictionary) -> void:
	if log_display:
		var bbcode_msg := _format_log(log_data)
		log_display.append_text(bbcode_msg + "\n")


func _format_log(log_data: Dictionary) -> String:
	var time: float = log_data.get("time", 0.0)
	var frame: int = log_data.get("frame", 0)
	var formatted_msg: String = (
		"[%7.3fs][F:%d][%s] %s %s - [%s] %s"
		% [
			time,
			frame,
			log_data.get("prefix", ""),
			log_data.get("context_str", ""),
			log_data.get("category", ""),
			log_data.get("level", ""),
			log_data.get("message", "")
		]
	)

	var level: String = log_data.get("level", "DEBUG")

	match level:
		"DEBUG":
			return "[color=gray]{0}[/color]".format([formatted_msg])
		"INFO":
			return "[b][color=cyan]{0}[/color][/b]".format([formatted_msg])
		"WARN":
			return "[b][color=yellow]{0}[/color][/b]".format([formatted_msg])
		"ERROR":
			return "[b][color=red]{0}[/color][/b]".format([formatted_msg])
	return formatted_msg


func _rebuild_log_display() -> void:
	log_display.clear()
	for log_data: Dictionary in _all_logs:
		var category: String = log_data.get("category", "")
		if category.is_empty():
			category = "Default"

		if _active_filters.get(category, true):
			_append_formatted_log(log_data)


func _on_clear_pressed() -> void:
	_all_logs.clear()
	log_display.clear()
	# Optionally clear filters too?
	for child: Node in filter_container.get_children():
		child.queue_free()
	_active_filters.clear()


# ------------- [Public Method] -------------
## stream logs from outside (legacy/raw string support)
func append_log(bbcode_text: String) -> void:
	if log_display:
		log_display.append_text(bbcode_text + "\n")


## add log with data for filtering
func add_log(log_data: Dictionary) -> void:
	_all_logs.append(log_data)

	var category: String = log_data.get("category", "")
	if category.is_empty():
		category = "Default"

	if not _active_filters.has(category):
		_add_filter_button(category)

	if _active_filters.get(category, true):
		_append_formatted_log(log_data)
