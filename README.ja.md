# D-Logger for Godot 4.3+

[English](README.md) | **日本語**

Godot向けの軽量かつ強力で拡張性の高いロギングシステム(になる予定)。
コンソールとファイルへの同時出力をサポート。
また、Project Settingsとの統合やインスタンス単位の柔軟な設定が可能。

---

## ✨ 特徴

- 📢 **マルチキャストロギング**: コンソールとファイルへ同時にログを出力。
- 🔍 **インタラクティブなフィルタリング**: エディタパネル上の動的なトグルボタンでカテゴリごとにログをフィルタリング。
- ⚡ **Solo モード**: カテゴリボタンを `Alt + Click` することで、そのカテゴリのみを表示（Solo）、または全表示に切り替え。
- ⚙️ **Project Settings 統合**: プレフィックス、ログレベル、ファイルパスなどの全体設定を Godot の Project Settings から直接管理できる。
- 🧩 **インスタンス単位の設定**: 特定のサブシステム向けに、独自のプレフィックスやログレベルを持つロガーを作成可能。
- 🎨 **リッチテキスト出力**: カラーコード化されたコンソールログにより、視認性が向上。
- 🔍 **コンテキストとカテゴリ**: オブジェクト参照やカテゴリ文字列を付与して、ログの追跡を容易に。
- ⚡ **パフォーマンス重視**: ログレベルが無効な場合、複雑なフォーマット処理を自動的にスキップ。
- 🛠️ **デバッグ専用設計**: コンソールおよびファイル出力はリリースビルドで自動的に無効化され、本番環境でのオーバーヘッドを防止。

---

## 📦 インストール

1. `addons/d_logger/` フォルダをプロジェクトの `addons/` ディレクトリにコピー。
2. **Project Settings > Plugins** から **D-Logger** を有効化。
3. `DLogger` という名前のシングルトン（Autoload）が自動的に登録される。

---

## 🚀 クイックスタート

### 基本的な使い方
どのスクリプトからでも `DLogger` シングルトンを使用できる：

```gdscript
DLogger.info("ゲームを開始した！")
DLogger.warn("メモリ不足を検知した。", [], "system")
DLogger.error("レベルの読み込みに失敗: {0}", ["level_1"])
```

### 高度なフォーマット
`String.format()` 形式のプレースホルダーをサポートしており、配列、辞書、または単一の値を渡せる：

```gdscript
# 配列を使用
DLogger.info("プレイヤー {0} が {1} に参加した", ["Alice", Vector2(100, 200)])

# 辞書を使用
DLogger.debug("ステータス: HP={hp}, MP={mp}", {"hp": 100, "mp": 50})

# 単一の値を使用
DLogger.debug("値: {0}", 42)
```

### コンテキストとカテゴリ
ログにメタデータを追加して追跡性を高める：

```gdscript
# cat: カテゴリ (String)
# ctx: コンテキスト (Object, 通常は 'self')
DLogger.debug("プレイヤーがジャンプした", [], "gameplay", self)
# 出力例: [...][D-Logger][player.gd:12][Player:<Node#123>] gameplay - [DEBUG] プレイヤーがジャンプした
```

---

## ⚙️ Project Settings

**Project Settings > Debug > D-Logger** からグローバル設定を変更できる：

| 設定項目 | 型 | デフォルト値 | 説明 |
|---------|------|---------|-------------|
| `prefix` | String | `"D-Logger"` | ログの共通プレフィックス。 |
| `enable_log` | Boolean | `true` | コンソール出力を有効化（デバッグビルドのみ）。 |
| `min_log_level` | Enum | `DEBUG` | 表示する最小レベル（DEBUG, INFO, WARN, ERROR）。 |
| `enable_file_log` | Boolean | `false` | ファイルへのログ出力を有効化（デバッグビルドのみ）。 |
| `log_file_path` | String | `user://debug.log` | ログファイルの保存先パス。 |

---

## 🔧 インスタンスごとのロガー

ネットワークやAIなど、特定のシステム専用のロガーが必要な場合は、個別のインスタンスを作成できる：

```gdscript
var network_log: DLoggerClass

func _init():
	# 引数: prefix, min_level, console_enabled, file_path
	network_log = DLoggerClass.new("NETWORK", 1) # 1 は INFO

func _ready():
	network_log.info("サーバーに接続中...")
```

---

## 📖 API リファレンス

### ロギングメソッド
すべてのメソッドは `true` を返す。これにより、`assert()` 内で使用してデバッグ時のみ実行させることが可能。

- `debug(msg, values=[], category="", context=null, prefix="")`
- `info(msg, values=[], category="", context=null, prefix="")`
- `warn(msg, values=[], category="", context=null, prefix="")`
- `error(msg, values=[], category="", context=null, prefix="")`

### レベルチェック
重い計算を伴うログ出力の前に使用すると効果的。

- `is_debug_enabled()`
- `is_info_enabled()`
- `is_warn_enabled()`
- `is_error_enabled()`

---

## 📝 出力形式

ログは以下の形式で出力される：
`[   time ][F:frame][prefix][file:line][context] category - [LEVEL] message`

**例:**
`[  1.234s][F:123][D-Logger][test.gd:42][Player:<Node#123>] gameplay - [DEBUG] キャラクタースポーン`

---

## 💡 ヒント

### リリースビルドでの挙動
デフォルトでは、D-Loggerは**リリースビルドで何も出力しない**。
これはパフォーマンスの低下やデバッグ情報の漏洩を防ぐための仕様。

特定のロジックをデバッグ時のみ実行したい場合は `assert` を活用するといいかもしれない：
```gdscript
assert(DLogger.debug("このロジックとログはデバッグビルドにのみ存在する"))
```

### ログファイルの場所
ログファイルは `user://` ディレクトリに保存される。
- **Windows**: `%APPDATA%\Godot\app_userdata\[プロジェクト名]\debug.log`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/[プロジェクト名]/debug.log`
- **Linux**: `~/.local/share/godot/app_userdata/[プロジェクト名]/debug.log`

