@tool
## Constant definitions used throughout D-Logger
extends Object

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
const AUTOLOAD_PATH := "res://addons/d_logger/d_logger.gd"

# --- Log Level Labels ---
# For Enum display in settings
const MIN_LEVEL_HINT_STRING := "Debug:0,Info:1,Warn:2,Error:3"

enum LogLevel { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }
