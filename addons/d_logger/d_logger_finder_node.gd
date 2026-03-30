@tool
class_name DLoggerFinder
extends DLoggerNodeBase


# ------------- [Callbacks] -------------
func _ready() -> void:
	var logger := DLoggerFunc.find_logger_from_ancestor(self)
	if logger:
		_logger = logger.get_logger()
