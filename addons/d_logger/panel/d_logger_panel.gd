@tool
extends Control

@onready var clear_button: Button = %ClearButton
@onready var log_display: RichTextLabel = %RichTextLabel


func _ready() -> void:
	clear_button.pressed.connect(_on_clear_pressed)
	log_display.bbcode_enabled = true
	# enable automatic scrolling
	log_display.scroll_following = true


## stream logs from outside
func append_log(bbcode_text: String) -> void:
	if log_display:
		log_display.append_text(bbcode_text + "\n")


func _on_clear_pressed() -> void:
	log_display.clear()
