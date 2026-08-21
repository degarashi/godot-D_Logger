@tool
class_name DLoggerFinder
extends DLoggerNodeBase

signal on_log_found(logger: Object)


# ------------- [Callbacks] -------------
func _ready() -> void:
	# The logger node's _ready() may not have run yet: _ready is called
	# children-first and siblings in tree order, and DLoggerNode creates its
	# internal logger in _ready(). Retry via a deferred call so every _ready
	# callback in the scene has completed before the final search.
	_find_logger()
	if not _logger:
		call_deferred("_find_logger")


# ------------- [Private Method] -------------
func _find_logger() -> void:
	var logger := DLoggerFunc.find_logger_from_ancestor(self)
	if logger:
		_logger = (
			logger.get_logger() if logger.has_method(&"get_logger") else logger
		)

	if _logger:
		on_log_found.emit(_logger)
