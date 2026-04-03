# D-Logger for Godot 4.3+

**日本語** | [English](README.md)

![D-Logger Preview](doc_images/d_logger_image.jpg)

Godot向けの軽量かつ強力で拡張性の高いロギングシステム。D-Loggerは、マルチ出力、インタラクティブなフィルタリング、Godotエディタとのシームレスな統合をサポートし、ログ管理を効率化する。

---

## ✨ 特徴

- 📢 **マルチキャストロギング**: コンソール、ファイル、および専用のエディタパネルへ同時にログを出力。
- 🔍 **インタラクティブな底部パネル**: リアルタイムでログを調査できるカスタムパネル。
  - **カテゴリフィルタリング**: 特定のカテゴリの表示/非表示を切り替え。`Alt + Click` でそのカテゴリのみを表示（Solo モード）。
  - **時間フィルタリング**: 直近 30秒、1分、5分のログを絞り込み。
  - **レベルフィルタリング**: DEBUG, INFO+, WARN+, ERROR の表示を素早く切り替え。
- ⚙️ **Project & Editor Settings**: プレフィックス、ログレベル、ファイルパスなどを Godot の設定メニューから直接管理。
- 🧩 **インスタンス単位の設定**: ネットワークやAIなど、特定のサブシステム向けに独自のプレフィックスやレベルを持つロガーを作成可能。
- 🎨 **リッチテキスト出力**: エディタパネル上で BBCode をサポートし、視認性の高いログ表示を実現。
- ⚡ **パフォーマンス重視**: ログレベルが無効な場合、複雑な文字列フォーマット処理を自動的にスキップ。
- 🛠️ **デバッグ専用設計**: コンソールおよびファイル出力はリリースビルドで自動的に無効化され、本番環境でのオーバーヘッドを防止。

---

## 📦 インストール

1. `addons/d_logger/` フォルダをプロジェクトの `addons/` ディレクトリにコピーする。
2. **Project > Project Settings > Plugins** から **D-Logger** を有効化する。
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
# 出力例: [  1.234s][F:123][D-Logger][Player] gameplay - [DEBUG] プレイヤーがジャンプした
```

---

## ⚙️ 設定

設定は **Editor > Editor Settings > D-Logger** から管理する（一部の値は実行時に Project Settings と同期される）：

| 設定項目 | 型 | デフォルト値 | 説明 |
|---------|------|---------|-------------|
| `prefix` | String | `"D-Logger"` | ログの共通プレフィックス。 |
| `enable_console_log` | Boolean | `false` | コンソール出力を有効化（デバッグビルドのみ）。 |
| `min_log_level` | Enum | `DEBUG` | 表示する最小レベル（DEBUG, INFO, WARN, ERROR）。 |
| `enable_file_log` | Boolean | `false` | ファイルへのログ出力を有効化（デバッグビルドのみ）。 |
| `log_file_path` | String | `user://debug.log` | ログファイルの保存先パス。 |
| `auto_activate_panel`| Boolean | `true` | デバッグ開始時に D-Logger パネルを自動表示。 |

---

## 🔧 インスタンスごとのロガー

特定のシステム専用のロガーが必要な場合は、個別のインスタンスを作成できる：

```gdscript
var network_log: DLoggerClass

func _init():
    # 引数: prefix, min_level, console_enabled, file_path
    network_log = DLoggerClass.new("NETWORK", DLoggerConstants.LogLevel.INFO)

func _ready():
    network_log.info("サーバーに接続中...")
```

---

## 📖 API リファレンス

### ロギングメソッド
すべてのメソッドは `true` を返す。これにより、`assert()` 内で使用してデバッグ時のみ実行させることが可能だ。

- `debug(msg, values=[], category="", context=null, prefix="")`
- `info(msg, values=[], category="", context=null, prefix="")`
- `warn(msg, values=[], category="", context=null, prefix="")`
- `error(msg, values=[], category="", context=null, prefix="")`

### レベルチェック
重い計算を伴うログ出力の前に使用すると効果的だ。

- `is_debug_enabled()`
- `is_info_enabled()`
- `is_warn_enabled()`
- `is_error_enabled()`

### エディタパネルのショートカット
- **Ctrl + L**: ログをクリア
- **Ctrl + C**: ログをクリップボードにコピー
- **Ctrl + S**: ログを `user://` 内のファイルに保存
- **1, 2, 3, 4**: ログレベルフィルタの切り替え

---

## 📝 出力形式

ログは以下の形式で出力される：
`[   time ][F:frame][prefix][file:line] [context] category - [LEVEL] message`

**例 (DEBUG):**
```
[  1.234s][F:123][D-Logger][Player] gameplay - [DEBUG] キャラクタースポーン
```

**注意:** `[file:line]`（ソースファイルと行番号）は、コンソールをスッキリさせるため **WARN** と **ERROR** レベルでのみ表示される。

---

## 💡 ヒント

### パフォーマンスを意識したロギング
ログ出力に重い計算が必要な場合は、レベルチェックで囲むこと：

```gdscript
if DLogger.is_debug_enabled():
    DLogger.debug("複雑な計算結果: {0}", [do_heavy_calc()])
```

### `assert()` との組み合わせ
ロギングメソッドは `true` を返すため、`assert` と組み合わせてデバッグ時のみログを出力し、失敗時にコンテキストを提供できる：

```gdscript
assert(DLogger.debug("このログはデバッグビルドでのみ出力される"))
```

---

## 🐛 トラブルシューティング

### コンソールにログが表示されない
- プラグインが **Project Settings** で有効になっているか確認する。
- **Editor Settings** の `enable_console_log` が `true` になっているか確認する。
- `min_log_level`（最小ログレベル）の設定を確認する。
- 注意：D-Logger はデフォルトで **リリースビルドでは何も出力しない**。

### ログファイルが作成されない
- 設定の `log_file_path` を確認する。
- デフォルトのパスは `user://debug.log` である。`user://` フォルダは、Godot エディタの **Project > Open User Data Folder** から開くことができる。
