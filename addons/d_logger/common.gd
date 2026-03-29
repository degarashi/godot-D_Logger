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
