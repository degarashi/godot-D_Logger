@tool
## Constant definitions used throughout D-Logger
class_name DLoggerConstants
extends Object

enum LogLevel { NOT_SPECIFIED = -1, DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }

# --- Project Settings Paths (Saved in project.godot) ---
const SETTING_PREFIX := "debug/d_logger/prefix"

# --- Editor Settings Paths (Saved in editor_settings-4.x.tres) ---
const EDITOR_SETTING_ENABLE_CONSOLE := "d_logger/enable_console_log"
const EDITOR_SETTING_MIN_LEVEL := "d_logger/min_log_level"
const EDITOR_SETTING_ENABLE_FILE := "d_logger/enable_file_log"
const EDITOR_SETTING_FILE_PATH := "d_logger/log_file_path"
const EDITOR_SETTING_AUTO_ACTIVATE_PANEL := "d_logger/auto_activate_panel"
const EDITOR_SETTING_AUTO_CLEAR_ON_START := "d_logger/auto_clear_on_start"

# --- Runtime Settings Paths (Accessed via ProjectSettings, but may be synced from EditorSettings) ---
const SETTING_ENABLE_CONSOLE := "debug/d_logger/enable_console_log"
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
const MIN_LEVEL_HINT_STRING = "DEBUG:0,INFO:1,WARN:2,ERROR:3"
