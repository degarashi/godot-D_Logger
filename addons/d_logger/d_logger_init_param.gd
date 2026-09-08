class_name DLoggerInitParam
extends Resource

## Tri-state console override. A plain bool cannot express "no override",
## so the inspector uses this enum instead of a Variant-typed property
## (which the inspector cannot edit meaningfully).
enum ConsoleOverride {
	USE_PROJECT_SETTINGS = -1,
	DISABLED = 0,
	ENABLED = 1,
}


# ------------- [Exports] -------------
@export var prefix_override: String = ""
@export var min_level_override := DLoggerConstants.LogLevel.NOT_SPECIFIED
@export var console_enabled_override: ConsoleOverride = (
	ConsoleOverride.USE_PROJECT_SETTINGS
)
@export var file_path_override: String = ""


# ------------- [Callbacks] -------------
func _init(
	p_prefix: String = "",
	p_min_level: DLoggerConstants.LogLevel = (
		DLoggerConstants.LogLevel.NOT_SPECIFIED
	),
	p_console_enabled: Variant = null,
	p_file_path: String = ""
) -> void:
	prefix_override = p_prefix
	min_level_override = p_min_level
	console_enabled_override = _to_console_override(p_console_enabled)
	file_path_override = p_file_path


# ------------- [Private Static Method] -------------
## Normalizes the constructor argument to the tri-state enum. Accepts
## the enum members as well as legacy bool/null values so existing
## call sites keep working.
static func _to_console_override(value: Variant) -> ConsoleOverride:
	if value is bool:
		return ConsoleOverride.ENABLED if value else ConsoleOverride.DISABLED
	if value is int:
		match value:
			ConsoleOverride.USE_PROJECT_SETTINGS:
				return ConsoleOverride.USE_PROJECT_SETTINGS
			ConsoleOverride.DISABLED:
				return ConsoleOverride.DISABLED
			ConsoleOverride.ENABLED:
				return ConsoleOverride.ENABLED
	if value == null:
		return ConsoleOverride.USE_PROJECT_SETTINGS
	push_warning(
		"DLoggerInitParam: ignoring invalid console override: %s" % value
	)
	return ConsoleOverride.USE_PROJECT_SETTINGS
