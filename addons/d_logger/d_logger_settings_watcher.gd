class_name DLoggerSettingsWatcher
extends RefCounted

## Tracks the runtime d_logger ProjectSettings values. ProjectSettings.
## settings_changed fires for ANY setting change (resolution, quality,
## other plugins...), so consumers rebuild their logger only when one of
## the d_logger keys actually drifted. Shared by DLoggerNode and the
## DLoggerClass static fallback so the snapshot-compare pattern lives
## in one place; the key list itself stays in
## DLoggerFunc.collect_d_logger_settings().

# ------------- [Private Variable] -------------
var _snapshot: Dictionary = {}


# ------------- [Callbacks] -------------
func _init() -> void:
	refresh()


# ------------- [Public Method] -------------
## Re-reads the current settings as the new baseline.
func refresh() -> void:
	_snapshot = DLoggerFunc.collect_d_logger_settings()


## Compares the live settings against the baseline. Returns true once
## per change and adopts the new baseline; returns false when nothing
## changed.
func poll() -> bool:
	var current := DLoggerFunc.collect_d_logger_settings()
	if current == _snapshot:
		return false
	_snapshot = current
	return true
