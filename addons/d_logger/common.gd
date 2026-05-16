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
			var internal_logger: Object = logger.get_logger()
			if has_logger_interface(internal_logger):
				return internal_logger

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


static func get_object_string(obj: Object) -> String:
	if obj is Node:
		return "[{0}]".format([obj.name])
	return "[{0}:{1}]".format([obj.get_class(), String.num_uint64(obj.get_instance_id())])


static func get_caller_info(level: String) -> Dictionary:
	# Release builds cannot use get_stack(), so we skip it entirely
	# Also skip for high-frequency logs (DEBUG, INFO) to maintain performance
	if not OS.is_debug_build() or level == "DEBUG" or level == "INFO":
		return {}

	var stack := get_stack()

	# Loop through the stack to find the first file outside the logger addon
	for i in range(stack.size()):
		var entry: Dictionary = stack[i]
		var source: String = entry.get("source", "")

		if not source.begins_with("res://addons/d_logger/"):
			return {
				"file": source,
				"line": entry.get("line", 0),
				"display": "[{file}:{line}]".format(
					{"file": source.get_file(), "line": entry.get("line", 0)}
				)
			}

	return {}


static func get_source_string(prefix: String, category: String) -> String:
	if category.is_empty() or category == prefix:
		return "[%s]" % prefix
	if prefix == DLoggerConstants.DEFAULT_PREFIX:
		return "[%s]" % category
	return "[%s:%s]" % [prefix, category]


static func get_formatted_line(
	time: float,
	frame: int,
	source_str: String,
	caller_info: Variant, # Can be String (old format) or Dictionary
	ctx_str: String,
	level: String,
	msg: String,
	use_bbcode: bool = false
) -> String:
	var caller_display := ""
	var caller_url := ""

	if caller_info is Dictionary and not caller_info.is_empty():
		caller_display = caller_info.get("display", "")
		caller_url = "%s:%d" % [caller_info.get("file", ""), caller_info.get("line", 0)]
	elif caller_info is String and not caller_info.is_empty():
		caller_display = caller_info

	var caller_part := ""
	if not caller_display.is_empty():
		if use_bbcode and not caller_url.is_empty():
			caller_part = " [url=%s]%s[/url]" % [caller_url, caller_display]
		else:
			caller_part = " " + caller_display

	var ctx_part := " " + ctx_str if not ctx_str.is_empty() else ""

	# [001.234s][F:123][D-Logger] [main.gd:10] [MyNode] - [WARN] Message
	return (
		"[%7.3fs][F:%d]%s%s%s - [%s] %s"
		% [
			time,
			frame,
			source_str,
			caller_part,
			ctx_part,
			level,
			msg,
		]
	)


static func format_log(
	msg: String,
	category: String,
	level: String,
	context: Object,
	prefix: String,
	p_caller_info: Variant = null
) -> String:
	# Convert to seconds (e.g., 1234ms -> 1.234s)
	var seconds := Time.get_ticks_msec() / 1000.0
	var frames := Engine.get_frames_drawn()

	var ctx_str := get_object_string(context) if context else ""
	var caller_info: Variant = p_caller_info if p_caller_info != null else get_caller_info(level)
	var source_str := get_source_string(prefix, category)

	# By default, use plain text for internal formatting (e.g. for console/file)
	return get_formatted_line(seconds, frames, source_str, caller_info, ctx_str, level, msg, false)
