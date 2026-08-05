class_name DLoggerPanelFormat
extends Object

## Static formatting helpers for the log panel display. Kept free of panel
## state (search, relative-time and selection are passed in as arguments) so
## the logic is unit-testable without a panel instance.


## Computes the filter tag list for a log: category segments when present,
## otherwise the prefix (unless it is the default "D-Logger"), otherwise
## "Default".
static func get_log_tags(log_data: Dictionary) -> Array[String]:
	var category: String = log_data.get("category", "")
	if not category.is_empty():
		var tags: Array[String] = []
		for tag in category.split("|"):
			var t := tag.strip_edges()
			if not t.is_empty():
				tags.append(t)
		if not tags.is_empty():
			return tags

	var prefix: String = log_data.get("prefix", "")
	if not prefix.is_empty() and prefix != DLoggerConstants.DEFAULT_PREFIX:
		return [prefix]

	return ["Default"]


## Formats a log as plain text (no BBCode) for clipboard/copy operations.
static func format_log_plain(log_data: Dictionary) -> String:
	var time: float = log_data.get("time", 0.0)
	var frame: int = log_data.get("frame", 0)
	var level: String = log_data.get("level", "DEBUG")
	var prefix: String = log_data.get("prefix", "")
	var category: String = log_data.get("category", "")
	var context_str: String = log_data.get("context_str", "")
	var caller_info = log_data.get("caller_info", {})
	var message: String = log_data.get("message", "")

	var source_str := DLoggerFunc.get_source_string(prefix, category, false)
	var formatted_msg := DLoggerFunc.get_formatted_line(
		time, frame, source_str, caller_info, context_str, level, message, false
	)

	var count: int = log_data.get("count", 1)
	if count > 1:
		formatted_msg += " (x{0})".format([count])

	return formatted_msg


## Formats a log for the RichTextLabel display with BBCode: clickable source
## links, level colors, selection color, optional search highlighting and
## optional relative timestamps.
static func format_log(
	log_data: Dictionary,
	search: DLoggerSearch,
	relative_time: bool,
	max_time: float,
	is_selected: bool = false
) -> String:
	var time: float = log_data.get("time", 0.0)
	var frame: int = log_data.get("frame", 0)
	var level: String = log_data.get("level", "DEBUG")
	var prefix: String = log_data.get("prefix", "")
	var category: String = log_data.get("category", "")
	var context_str: String = log_data.get("context_str", "")
	var caller_info = log_data.get("caller_info", {})
	var message: String = log_data.get("message", "")

	# Escape brackets before BBCode embedding/highlighting so user-provided
	# message text cannot inject markup (e.g. [url=filter:...] link spoofing).
	message = DLoggerFunc.escape_bbcode(message)

	# Highlight search keyword in the message text
	if not search.is_empty():
		message = search.highlight(message)

	# Convert to relative timestamp when enabled.
	if relative_time:
		time = time - max_time

	# Generate source string with clickable filter URLs matching actual filter
	# button texts (from get_log_tags). Must handle the case where the
	# displayed text (prefix "D-Logger") differs from the tag ("Default")
	# for category-less logs with default prefix.
	var log_tags: Array = log_data.get("_log_tags", [])
	var source_str: String
	if log_tags.is_empty():
		source_str = DLoggerFunc.get_source_string(prefix, category, true)
	elif category.is_empty() and prefix == DLoggerConstants.DEFAULT_PREFIX:
		# Show [D-Logger] but URL target = "Default" (the actual filter tag).
		# Escape both segments so a bracket in the tag/prefix cannot break
		# out of the [url=...] tag and inject arbitrary BBCode.
		source_str = "[[url=filter:{0}]{1}[/url]]".format([
			DLoggerFunc.escape_bbcode(log_tags[0]),
			DLoggerFunc.escape_bbcode(prefix),
		])
	else:
		source_str = DLoggerFunc.get_source_string(prefix, category, true)

	var formatted_msg := DLoggerFunc.get_formatted_line(
		time, frame, source_str, caller_info, context_str, level, message, true
	)

	var count: int = log_data.get("count", 1)
	if count > 1:
		formatted_msg += " [b](x{0})[/b]".format([count])

	var text_color := ""
	if is_selected:
		text_color = "#ffffff"
	else:
		match level:
			"DEBUG":
				text_color = "gray"
			"INFO":
				text_color = "cyan"
			"WARN":
				text_color = "yellow"
			"ERROR":
				text_color = "red"

	var result: String
	if is_selected:
		result = ("[b][color={0}]{1}[/color][/b]".format(
			[text_color, formatted_msg]
		))
	elif not text_color.is_empty():
		var is_bold := level in ["INFO", "WARN", "ERROR"]
		if is_bold:
			result = ("[b][color={0}]{1}[/color][/b]".format(
				[text_color, formatted_msg]
			))
		else:
			result = ("[color={0}]{1}[/color]".format(
				[text_color, formatted_msg]
			))
	else:
		result = formatted_msg

	return result
