class_name DLoggerFunc
extends Object


## Checks if the given object meets the requirements of a logger
## @param logger The object to be checked
## @return True if it implements all required methods, false otherwise
static func is_logger(logger: Object) -> bool:
	if not logger:
		return false

	const REQUIRED_METHODS: PackedStringArray = [
		"is_debug_enabled",
		"is_info_enabled",
		"is_warn_enabled",
		"is_error_enabled",
		"debug",
		"info",
		"warn",
		"error"
	]

	for method_name: String in REQUIRED_METHODS:
		if not logger.has_method(method_name):
			return false

	return true


## Searches for a specific interface in the parent direction from the specified node
## @param start_node The node to start the search from
## @return The child object implementing the logger interface if found, null otherwise
static func find_logger_from_ancestor(start_node: Node) -> Object:
	var current := start_node
	while current:
		for child: Node in current.get_children():
			if is_logger(child):
				return child
		current = current.get_parent()

	return null
