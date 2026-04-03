# D-Logger for Godot 4.3+

[日本語版 (Japanese)](README.ja.md) | **English**

![D-Logger Preview](doc_images/d_logger_image.jpg)

A lightweight, powerful, and extensible logging system for Godot Engine. D-Logger provides a centralized way to manage logs with support for multiple outputs, interactive filtering, and seamless integration with the Godot Editor.

---

## ✨ Features

- 📢 **Multicast Logging**: Simultaneously output logs to the console, a file, and the dedicated editor panel.
- 🔍 **Interactive Bottom Panel**: A custom editor panel for real-time log inspection.
  - **Category Filtering**: Toggle display for specific categories. `Alt + Click` to "Solo" a category.
  - **Time Filtering**: View logs from the last 30s, 1m, or 5m.
  - **Level Filtering**: Quickly switch between DEBUG, INFO+, WARN+, and ERROR views.
- ⚙️ **Project & Editor Settings**: Configure prefixes, log levels, and file paths directly from Godot's settings menus.
- 🧩 **Instance-based Configuration**: Create dedicated logger instances for specific subsystems (e.g., Network, AI) with unique prefixes and levels.
- 🎨 **Rich Text Output**: BBCode-supported log display in the editor panel for better visibility.
- ⚡ **Performance Optimized**: Automatically skips complex string formatting when the log level is disabled.
- 🛠️ **Debug-Only by Design**: Console and file outputs are automatically disabled in release builds to prevent performance overhead.

---

## 📦 Installation

1. Copy the `addons/d_logger/` folder into your project's `addons/` directory.
2. Go to **Project > Project Settings > Plugins** and enable **D-Logger**.
3. A singleton named `DLogger` will be automatically registered as an Autoload.

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
Supports `String.format()` placeholders. You can pass an Array, Dictionary, or a single value:

```gdscript
# Using an Array
DLogger.info("Player {0} joined at {1}", ["Alice", Vector2(100, 200)])

# Using a Dictionary
DLogger.debug("Stats: HP={hp}, MP={mp}", {"hp": 100, "mp": 50})

# Using a Single Value
DLogger.debug("Value: {0}", 42)
```

### Context and Categories
Add metadata to your logs for easier tracking:

```gdscript
# cat: Category (String)
# ctx: Context (Object, usually 'self')
DLogger.debug("Player jumped", [], "gameplay", self)
# Output: [  1.234s][F:123][D-Logger][Player] gameplay - [DEBUG] Player jumped
```

---

## ⚙️ Configuration

Settings are managed via **Editor > Editor Settings > D-Logger** (some values sync to Project Settings at runtime):

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `prefix` | String | `"D-Logger"` | Global prefix for all logs. |
| `enable_console_log` | Boolean | `false` | Enable console output (Debug builds only). |
| `min_log_level` | Enum | `DEBUG` | Minimum level to display (DEBUG, INFO, WARN, ERROR). |
| `enable_file_log` | Boolean | `false` | Enable logging to a local file. |
| `log_file_path` | String | `user://debug.log` | Path where the log file is saved. |
| `auto_activate_panel`| Boolean | `true` | Show the D-Logger panel when debugging starts. |

---

## 🔧 Custom Logger Instances

For specific systems like Networking or AI, you can create dedicated logger instances:

```gdscript
var network_log: DLoggerClass

func _init():
    # Arguments: prefix, min_level, console_enabled, file_path
    network_log = DLoggerClass.new("NETWORK", DLoggerConstants.LogLevel.INFO)

func _ready():
    network_log.info("Connecting to server...")
```

---

## 📖 API Reference

### Logging Methods
All methods return `true`, allowing them to be used inside `assert()` for debug-only execution.

- `debug(msg, values=[], category="", context=null, prefix="")`
- `info(msg, values=[], category="", context=null, prefix="")`
- `warn(msg, values=[], category="", context=null, prefix="")`
- `error(msg, values=[], category="", context=null, prefix="")`

### Level Checks
Useful for skipping heavy calculations when logging is disabled.

- `is_debug_enabled()`
- `is_info_enabled()`
- `is_warn_enabled()`
- `is_error_enabled()`

### Editor Panel Shortcuts
- **Ctrl + L**: Clear logs
- **Ctrl + C**: Copy logs to clipboard
- **Ctrl + S**: Save logs to a file in `user://`
- **1, 2, 3, 4**: Switch between log level filters

---

## 📝 Output Format

Logs follow this structure:
`[   time ][F:frame][prefix][file:line] [context] category - [LEVEL] message`

**Example (DEBUG):**
```
[  1.234s][F:123][D-Logger][Player] gameplay - [DEBUG] Character spawned
```

**Note:** `[file:line]` is only included for **WARN** and **ERROR** levels to keep the console clean.

---

## 💡 Pro Tips

### Performance Tip
If a log message requires expensive calculations, wrap it in a level check:

```gdscript
if DLogger.is_debug_enabled():
    DLogger.debug("Complex result: {0}", [do_heavy_calc()])
```

### Using with `assert()`
Since logging methods return `true`, you can use them in `assert` to ensure they only run in debug builds and provide context on failure:

```gdscript
assert(DLogger.debug("This only runs in debug builds"))
```

---

## 🐛 Troubleshooting

### Logs not appearing in console?
- Ensure the plugin is enabled in **Project Settings**.
- Check if `enable_console_log` is `true` in **Editor Settings**.
- Verify your `min_log_level`.
- Remember: D-Logger defaults to **silence in Release builds**.

### Log file not found?
- Check your `log_file_path` in settings.
- Default path is `user://debug.log`. You can find the `user://` folder via **Project > Open User Data Folder**.
