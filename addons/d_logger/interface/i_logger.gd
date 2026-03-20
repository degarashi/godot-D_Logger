class_name ILogger
extends InterfaceBase


func debug(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	_impl.debug(msg, category, context, prefix)


func info(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	_impl.info(msg, category, context, prefix)


func warn(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	_impl.warn(msg, category, context, prefix)


func error(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	_impl.error(msg, category, context, prefix)
