@tool
class_name DLoggerFinder
extends DLoggerNodeBase

signal on_log_found(logger: Object)


# ------------- [Callbacks] -------------
func _ready() -> void:
	var logger := DLoggerFunc.find_logger_from_ancestor(self)
	if logger:
		_logger = logger.get_logger()

	if _logger:
		on_log_found.emit(_logger)
