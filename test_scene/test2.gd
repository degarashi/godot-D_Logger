extends Node

# ------------- [Public Variable] -------------
@onready var d_logger_finder: DLoggerFinder = %DLoggerFinder


# ------------- [Callbacks] -------------
func _ready() -> void:
	if d_logger_finder:
		DLogger.info("DLoggerFinder detected successfully")
		if d_logger_finder.get_logger():
			DLogger.info("Valid logger instance obtained from DLoggerFinder")
