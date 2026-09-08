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
	# Only one retry is attempted: loggers added dynamically after that
	# point are not picked up and must be wired manually.
	_find_logger()
	if not _logger:
		call_deferred("_find_logger")


# ------------- [Private Method] -------------
func _find_logger() -> void:
	var found := DLoggerFunc.find_logger_from_ancestor(self)
	if found:
		# Unwrap container nodes (e.g. DLoggerNode) to their inner
		# RefCounted logger so the typed assignment below stays valid.
		var candidate: Variant = (
			found.get_logger() if found.has_method(&"get_logger") else found
		)
		# Only a DLoggerClass fits the typed _logger field; foreign
		# duck-typed implementations are skipped instead of erroring
		# on assignment. Warn so the silent skip does not confuse:
		# the host node looks like a logger but is never used.
		if candidate is DLoggerClass:
			_logger = candidate
		elif candidate != null:
			push_warning(
				"DLoggerFinder: skipping non-DLoggerClass logger on %s" % found
			)

	if _logger:
		on_log_found.emit(_logger)
