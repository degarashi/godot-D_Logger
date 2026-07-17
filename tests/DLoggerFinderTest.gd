class_name DLoggerFinderTest
extends GdUnitTestSuite

const _FINDER = preload("res://addons/d_logger/d_logger_finder_node.gd")
const _NODE_BASE = preload("res://addons/d_logger/d_logger_node_base.gd")
const _CLASS = preload("res://addons/d_logger/d_logger.gd")


# ------------- [Constructor] -------------
func test_init() -> void:
	var finder := _FINDER.new()
	assert_object(finder).is_not_null()
	finder.free()


func test_is_dlogger_node_base() -> void:
	var finder := _FINDER.new()
	assert_bool(finder is DLoggerNodeBase)
	finder.free()


# ------------- [get_logger - Before Ready] -------------
func test_get_logger_before_ready() -> void:
	var finder := _FINDER.new()
	# Before _ready, _logger is null
	assert_object(finder.get_logger()).is_null()
	finder.free()


# ------------- [on_log_found Signal] -------------
func test_has_on_log_found_signal() -> void:
	var finder := _FINDER.new()
	assert_bool(finder.has_signal(&"on_log_found"))
	finder.free()


# ------------- [Ancestor Search Integration] -------------
func test_finder_with_logger_ancestor() -> void:
	# Create a parent node with a logger
	var parent := Node.new()
	var logger_node := _NODE_BASE.new()
	logger_node._logger = _CLASS.new("PARENT_LOGGER")
	parent.add_child(logger_node)

	# Create finder as child
	var finder := _FINDER.new()
	parent.add_child(finder)

	# Trigger _ready
	finder._ready()

	# Finder should have found the logger
	assert_object(finder.get_logger()).is_not_null()
	assert_object(finder.get_logger()).is_equal(logger_node._logger)

	finder.free()
	logger_node.free()
	parent.free()


func test_finder_without_logger_ancestor() -> void:
	# Create a parent without any logger
	var parent := Node.new()
	var finder := _FINDER.new()
	parent.add_child(finder)

	# Trigger _ready
	finder._ready()

	# Finder should not have found a logger
	assert_object(finder.get_logger()).is_null()

	finder.free()
	parent.free()


func test_finder_with_nested_logger_ancestor() -> void:
	# Create a deep hierarchy: grandparent -> parent -> child -> finder
	var grandparent := Node.new()
	var parent := Node.new()
	var child := Node.new()

	var logger_node := _NODE_BASE.new()
	logger_node._logger = _CLASS.new("GRANDPARENT_LOGGER")
	grandparent.add_child(logger_node)
	grandparent.add_child(parent)
	parent.add_child(child)

	var finder := _FINDER.new()
	child.add_child(finder)

	# Trigger _ready
	finder._ready()

	# Finder should have found the logger from grandparent
	assert_object(finder.get_logger()).is_not_null()
	assert_object(finder.get_logger()).is_equal(logger_node._logger)

	finder.free()
	logger_node.free()
	child.free()
	parent.free()
	grandparent.free()


func test_finder_with_multiple_ancestors() -> void:
	# Create hierarchy with multiple loggers - should find nearest
	var root := Node.new()
	var logger1 := _NODE_BASE.new()
	logger1._logger = _CLASS.new("ROOT_LOGGER")
	root.add_child(logger1)

	var parent := Node.new()
	var logger2 := _NODE_BASE.new()
	logger2._logger = _CLASS.new("PARENT_LOGGER")
	root.add_child(parent)
	parent.add_child(logger2)

	var child := Node.new()
	parent.add_child(child)

	var finder := _FINDER.new()
	child.add_child(finder)

	# Trigger _ready
	finder._ready()

	# Finder should find the nearest logger (parent's logger)
	assert_object(finder.get_logger()).is_equal(logger2._logger)

	finder.free()
	logger2.free()
	child.free()
	logger1.free()
	parent.free()
	root.free()


# ------------- [Finder with Direct Logger Object] -------------
func test_finder_with_direct_logger_object() -> void:
	# Test with a raw DLoggerClass attached to ancestor
	var parent := Node.new()
	parent.set_meta("logger", _CLASS.new("META_LOGGER"))

	var finder := _FINDER.new()
	parent.add_child(finder)

	# The finder uses DLoggerFunc.find_logger_from_ancestor
	# which searches for nodes with get_logger method
	# A raw DLoggerClass won't be found by node traversal
	finder._ready()

	# Without a DLoggerNodeBase ancestor, logger is null
	assert_object(finder.get_logger()).is_null()

	finder.free()
	parent.free()


# ------------- [Signal Emission] -------------
var _signal_emitted := false
var _signal_logger: Variant = null
var _signal_count := 0


func _on_log_found(l: Variant) -> void:
	_signal_emitted = true
	_signal_logger = l
	_signal_count += 1


func test_on_log_found_emitted_with_ancestor() -> void:
	var parent := Node.new()
	var logger_node := _NODE_BASE.new()
	var test_logger := _CLASS.new("SIGNAL_TEST")
	logger_node._logger = test_logger
	parent.add_child(logger_node)

	var finder := _FINDER.new()
	_signal_emitted = false
	finder.on_log_found.connect(_on_log_found)
	parent.add_child(finder)
	finder._ready()

	assert_bool(_signal_emitted).is_true()

	finder.free()
	logger_node.free()
	parent.free()


func test_on_log_found_emits_correct_logger() -> void:
	var parent := Node.new()
	var logger_node := _NODE_BASE.new()
	var test_logger := _CLASS.new("SIGNAL_TEST")
	logger_node._logger = test_logger
	parent.add_child(logger_node)

	var finder := _FINDER.new()
	_signal_logger = null
	finder.on_log_found.connect(_on_log_found)
	parent.add_child(finder)
	finder._ready()

	assert_object(_signal_logger).is_not_null()
	assert_object(_signal_logger).is_equal(test_logger)

	finder.free()
	logger_node.free()
	parent.free()


func test_on_log_found_not_emitted_without_ancestor() -> void:
	var parent := Node.new()

	var finder := _FINDER.new()
	_signal_emitted = false
	finder.on_log_found.connect(_on_log_found)
	parent.add_child(finder)
	finder._ready()

	assert_bool(_signal_emitted).is_false()

	finder.free()
	parent.free()


func test_on_log_found_with_nested_ancestor() -> void:
	# Hierarchy:
	#   root
	#   ├── logger_node (has logger)
	#   └── mid
	#       └── leaf
	#           └── finder
	# find_logger_from_ancestor walks UP and finds logger_node as sibling of mid
	var root := Node.new()
	var logger_node := _NODE_BASE.new()
	logger_node._logger = _CLASS.new("NESTED")
	root.add_child(logger_node)

	var mid := Node.new()
	root.add_child(mid)
	var leaf := Node.new()
	mid.add_child(leaf)

	var finder := _FINDER.new()
	_signal_logger = null
	finder.on_log_found.connect(_on_log_found)
	leaf.add_child(finder)
	finder._ready()

	assert_object(_signal_logger).is_not_null()

	finder.free()
	leaf.free()
	mid.free()
	logger_node.free()
	root.free()


func test_on_log_found_multiple_finders() -> void:
	var parent := Node.new()
	var logger_node := _NODE_BASE.new()
	logger_node._logger = _CLASS.new("MULTI")
	parent.add_child(logger_node)

	_signal_count = 0
	var finder1 := _FINDER.new()
	var finder2 := _FINDER.new()
	finder1.on_log_found.connect(_on_log_found)
	finder2.on_log_found.connect(_on_log_found)
	parent.add_child(finder1)
	parent.add_child(finder2)
	finder1._ready()
	finder2._ready()

	assert_int(_signal_count).is_equal(2)

	finder1.free()
	finder2.free()
	logger_node.free()
	parent.free()
