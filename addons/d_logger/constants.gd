@tool
## Constant definitions used throughout D-Logger
extends Object

enum LogLevel { NOT_SPECIFIED = -1, DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }

# --- Project Settings Paths ---
const SETTING_PREFIX := "debug/d_logger/prefix"
const SETTING_ENABLE := "debug/d_logger/enable_log"
const SETTING_MIN_LEVEL := "debug/d_logger/min_log_level"
const SETTING_ENABLE_FILE := "debug/d_logger/enable_file_log"
const SETTING_FILE_PATH := "debug/d_logger/log_file_path"

# --- Default Values ---
const DEFAULT_PREFIX := "D-Logger"
const DEFAULT_FILE_PATH := "user://debug.log"

# --- Autoload Info ---
const AUTOLOAD_NAME := "DLogger"
const AUTOLOAD_PATH := "res://addons/d_logger/d_logger_node.gd"

# --- Log Level Labels ---
# For Enum display in settings
const MIN_LEVEL_HINT_STRING := "Debug:0,Info:1,Warn:2,Error:3"


static func _get_caller_info() -> String:
	var stack := get_stack()
	var caller_info := ""
	for i in range(stack.size()):
		var entry: Dictionary = stack[i]
		var source: String = entry.get("source", "")
		if not source.begins_with("res://addons/d_logger/"):
			caller_info = "[{file}:{line}]".format(
				{"file": source.get_file(), "line": entry.get("line", 0)}
			)
			break

	return caller_info


static func format_log(
	msg: String, category: String, level: String, context: Object, prefix: String
) -> String:
	# Convert to seconds (e.g., 1234ms -> 1.234s)
	var seconds := Time.get_ticks_msec() / 1000.0
	var cat_str := category

	# Build context information
	var ctx_str := ""
	if context:
		# Display object name and hash (ID)
		ctx_str = "[%s:%d]" % [context.get_class(), context.get_instance_id()]

	# 7 characters total, 3 decimal places
	return (
		"[%7.3fs][%s]%s%s %s - [%s] %s"
		% [
			seconds,
			prefix,
			_get_caller_info(),
			ctx_str,
			cat_str,
			level,
			msg,
		]
	)
