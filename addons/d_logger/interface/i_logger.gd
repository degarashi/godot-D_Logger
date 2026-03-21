class_name ILogger
extends InterfaceBase


func debug(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_p_prefix: String = ""
) -> void:
	_impl.debug(_msg, _values, _category, _context, _p_prefix)


func info(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_p_prefix: String = ""
) -> void:
	_impl.info(_msg, _values, _category, _context, _p_prefix)


func warn(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_p_prefix: String = ""
) -> void:
	_impl.warn(_msg, _values, _category, _context, _p_prefix)


func error(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_p_prefix: String = ""
) -> void:
	_impl.error(_msg, _values, _category, _context, _p_prefix)


func is_debug_enabled() -> bool:
	return _impl.is_debug_enabled()


func is_info_enabled() -> bool:
	return _impl.is_info_enabled()


func is_warn_enabled() -> bool:
	return _impl.is_warn_enabled()


func is_error_enabled() -> bool:
	return _impl.is_error_enabled()


static func cast(obj: Object) -> ILogger:
	return Interface.as_interface(obj, ILogger)
