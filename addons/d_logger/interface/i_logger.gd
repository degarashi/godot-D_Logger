class_name ILogger
extends InterfaceBase


func debug(msg: Variant, category: String = "", context: Object = null) -> void:
	_impl.debug(msg, category, context)


func info(msg: Variant, category: String = "", context: Object = null) -> void:
	_impl.info(msg, category, context)


func warn(msg: Variant, category: String = "", context: Object = null) -> void:
	_impl.warn(msg, category, context)


func error(msg: Variant, category: String = "", context: Object = null) -> void:
	_impl.error(msg, category, context)
