class_name DLoggerFunc
extends Object


## @brief Checks if the given object meets the requirements of a logger interface
## @param logger The object to be checked
## @return True if it implements all required methods, false otherwise
static func has_logger_interface(logger: Object) -> bool:
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


## @brief Retrieves a logger from a node or an object
## @param logger The object to attempt to get the logger from
## @return The child object implementing the logger interface if found, null otherwise
static func get_logger(logger: Object) -> Object:
	if not logger:
		return null
	if has_logger_interface(logger):
		return logger

	if logger is Node:
		if logger.has_method("get_logger"):
			logger = logger.get_logger()

		if not logger:
			return null

	return null


## @brief Validates if the object is an active logger
## @param logger The object to be checked
## @return True if it is a valid logger, false otherwise
static func is_logger(logger: Object) -> bool:
	return get_logger(logger) != null


## Searches for a specific interface in the parent direction from the specified node
## @param start_node The node to start the search from
## @return The child object implementing the logger interface if found, null otherwise
static func find_logger_from_ancestor(start_node: Node) -> Object:
	var current := start_node
	while current:
		for child: Node in current.get_children():
			if child == start_node:
				continue
			var logger := get_logger(child)
			if logger:
				return logger
		current = current.get_parent()

	return null
