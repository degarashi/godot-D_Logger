# D-Logger for Godot 4.3+

**English** | [日本語](README.ja.md)

A lightweight, powerful, and extensible logging system for Godot. It supports simultaneous output to the console and files, with seamless Project Settings integration and flexible per-instance configuration.

---

## ✨ Features

- 📢 **Multicast Logging**: Simultaneously output logs to the Godot console and a file.
- 🔍 **Interactive Filtering**: Filter logs by category in the editor panel with dynamic toggle buttons.
- ⚡ **Solo Mode**: `Alt + Click` a category button to show only that category (solo), or toggle all back.
- ⚙️ **Project Settings Integration**: Manage global defaults (prefix, log level, file path) directly from Godot's Project Settings UI.
- 🧩 **Per-Instance Configuration**: Create specialized loggers for specific subsystems with their own prefix or log level overrides.
- 🎨 **Rich Text Output**: Color-coded console logs for instant visual feedback.
- 🔍 **Context & Categories**: Tag logs with object references or category strings for effortless traceability.
- ⚡ **Performance Conscious**: Automatically skips expensive formatting if the target log level is disabled.
- 🛠️ **Debug-Only by Design**: Console and file output are automatically disabled in release builds to ensure zero production overhead.

---

## 📦 Installation

1. Copy the `addons/d_logger/` folder into your project's `addons/` directory.
2. Go to **Project Settings > Plugins** and enable **D-Logger**.
3. A singleton named `DLogger` (Autoload) will be automatically registered.

---

## 🚀 Quick Start

### Basic Usage
Use the `DLogger` singleton from any script:

```gdscript
DLogger.info("Game started!")
DLogger.warn("Low memory detected.", [], "system")
DLogger.error("Failed to load level: {0}", ["level_1"])
```

### Advanced Formatting
D-Logger supports `String.format()` style placeholders with Arrays, Dictionaries, or single values:

```gdscript
# Using an Array
DLogger.info("Player {0} joined at {1}", ["Alice", Vector2(100, 200)])

# Using a Dictionary
DLogger.debug("Stats: HP={hp}, MP={mp}", {"hp": 100, "mp": 50})

# Using a single value
DLogger.debug("Value: {0}", 42)
```

### Context & Categories
Add metadata to your logs for better filtering:

```gdscript
# cat: Category (String)
# ctx: Context (Object, usually 'self')
DLogger.debug("Player jumped", [], "gameplay", self)
# Example Output: [  1.234s][F:123][D-Logger][Player] gameplay - [DEBUG] Player jumped
```

---

## ⚙️ Project Settings

Change global defaults in **Project Settings > Debug > D-Logger**:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `prefix` | String | `"D-Logger"` | Global prefix for all logs. |
| `enable_log` | Boolean | `true` | Enable console output (Debug builds only). |
| `min_log_level` | Enum | `DEBUG` | Minimum level to display (DEBUG, INFO, WARN, ERROR). |
| `enable_file_log` | Boolean | `false` | Enable logging to a file (Debug builds only). |
| `log_file_path` | String | `user://debug.log` | Destination path for the log file. |

---

## 🔧 Per-Instance Loggers

For dedicated logging in specific systems (e.g., Network, AI), you can create individual instances:

```gdscript
var network_log: DLoggerClass

func _init():
	# Parameters: prefix, min_level, console_enabled, file_path
	network_log = DLoggerClass.new("NETWORK", 1) # 1 is INFO

func _ready():
	network_log.info("Connecting to server...")
```

---

## 📖 API Reference

### Logging Methods
All methods return `true`, allowing them to be used within `assert()` for debug-only execution.

- `debug(msg, values=[], category="", context=null, prefix="")`
- `info(msg, values=[], category="", context=null, prefix="")`
- `warn(msg, values=[], category="", context=null, prefix="")`
- `error(msg, values=[], category="", context=null, prefix="")`

### Level Checks
Useful for skipping heavy computations before logging:

- `is_debug_enabled()`
- `is_info_enabled()`
- `is_warn_enabled()`
- `is_error_enabled()`

---

## 📝 Output Format

Logs follow this structure:
`[   time ][F:frame][prefix][file:line] [context] category - [LEVEL] message`

**Example (DEBUG):**
```
[  1.234s][F:123][D-Logger][Player] gameplay - [DEBUG] Character spawned
```

**Example (WARN):**
```
[  1.345s][F:130][D-Logger][test.gd:42] [Player] gameplay - [WARN] Low health
```

**Format breakdown:**
- `[time]` - Elapsed time in seconds
- `[F:frame]` - Total frames drawn since the game started
- `[prefix]` - Logger prefix (default or custom)
- `[file:line]` - Source file and line number (**WARN and ERROR only**)
- `[context]` - Object context (if provided)
- `category` - Log category string (if provided)
- `[LEVEL]` - Log level (DEBUG, INFO, WARN, ERROR)
- `message` - Formatted log message

---

## 💡 Tips

### Release Build Behavior
By default, D-Logger **does not output anything** in release builds. This is intentional to prevent performance hits and debug info leaks.

If you want to ensure specific logic only runs in debug, use `assert`:
```gdscript
assert(DLogger.debug("This logic and log only exists in debug builds"))
```

### Log File Location
Log files are stored in the `user://` directory:
- **Windows**: `%APPDATA%\Godot\app_userdata\[ProjectName]\debug.log`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/[ProjectName]/debug.log`
- **Linux**: `~/.local/share/godot/app_userdata/[ProjectName]/debug.log`

---

## 📚 Common Patterns & Examples

### Performance-Conscious Logging
Skip expensive computations if the log level is disabled:

```gdscript
# Bad: expensive_calculation() runs even if debug is disabled
DLogger.debug("Result: {0}", [expensive_calculation()])

# Good: expensive_calculation() only runs if debug is enabled
if DLogger.is_debug_enabled():
    DLogger.debug("Result: {0}", [expensive_calculation()])
```

### Categorized Logging
Organize logs by subsystem for easy filtering:

```gdscript
# In player.gd
DLogger.warn("Health critically low", [], "gameplay", self)

# In network_manager.gd
DLogger.info("Connecting to {0}:{1}", [ip, port], "network", self)

# In audio_manager.gd
DLogger.error("Failed to load audio: {0}", [path], "audio", self)
```

### Per-System Loggers
Create dedicated loggers for specific subsystems:

```gdscript
# In network_manager.gd
extends Node

var net_log: DLoggerClass

func _init():
    net_log = DLoggerClass.new("NET", DLoggerConstants.LogLevel.DEBUG)

func connect_to_server(host: String, port: int) -> bool:
    net_log.info("Attempting connection to {0}:{1}", [host, port])
    # ... connection logic
    return true
```

### Integration with `assert()`
Use D-Logger with `assert()` for debug-only assertions:

```gdscript
func set_health(value: int) -> void:
    assert(value >= 0 and DLogger.warn("Health cannot be negative: {0}", [value]))
    _health = max(0, value)
```

---

## 🐛 Troubleshooting

### No logs appear in the console
- **Check 1**: Is D-Logger enabled in **Project Settings > Plugins**?
- **Check 2**: Is `enable_log` set to `true` in **Project Settings > Debug > D-Logger**?
- **Check 3**: Is your log level at or above `min_log_level`? (e.g., if `min_log_level` is INFO, DEBUG logs won't show)
- **Check 4**: Is this a release build? (Logs are disabled in release builds by default)

### File log is not being created
- **Check 1**: Is `enable_file_log` enabled in **Project Settings > Debug > D-Logger**?
- **Check 2**: Do you have write permissions to the `log_file_path` directory?
- **Check 3**: Try setting `log_file_path` to `user://debug.log` first to ensure the `user://` directory exists
- **Check 4**: Is this a debug build? (File logging is disabled in release builds by default)

### Custom logger instance not working
- **Check 1**: Make sure you're creating it with `DLoggerClass.new()`, not `DLogger.new()`
- **Check 2**: Verify the min_level parameter is correct (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR)
- **Check 3**: Ensure the instance is not being garbage collected before use (store it as a member variable)
