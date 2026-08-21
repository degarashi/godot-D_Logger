# D-Logger for Godot 4.7+

**日本語** | [English](README.md)

![D-Logger Preview](doc_images/d_logger_image.jpg)

Godot向けの軽量かつ強力で拡張性の高いロギングシステム。D-Loggerは、マルチ出力、インタラクティブなフィルタリング、Godotエディタとのシームレスな統合をサポートし、ログ管理を効率化する。

---

## ✨ 特徴

- 📢 **マルチキャストロギング**: コンソール、ファイル、および専用のエディタパネルへ同時にログを出力。
- 📁 **ファイル出力とローテーション**: ログファイルは 10MB で自動ローテーションされ、バックアップ (`.1`) を1世代だけ保持する。
- 🔍 **インタラクティブな底部パネル**: リアルタイムでログを調査できるカスタムパネル。
  - **カテゴリフィルタリング**: 特定のカテゴリの表示/非表示を切り替え。`Alt + Click` でそのカテゴリのみを表示（Solo モード）。
  - **時間フィルタリング**: 直近 30秒、1分、5分のログを絞り込み。
  - **レベルフィルタリング**: DEBUG, INFO+, WARN+, ERROR の表示を素早く切り替え。
  - **検索 & 正規表現**: テキスト検索または正規表現でリアルタイムフィルタリング。大文字小文字の区別も可能。
  - **ログスタッキング**: 同一の連続ログエントリは `(xN)` カウンターでスタック表示。
  - **選択 & ドラッグ選択**: クリック、Ctrl+Click、ドラッグでログを選択。選択行または表示中の全ログをコピー可能。
  - **折り返し & フォントサイズ**: 折り返し表示のON/OFF切り替え、Ctrl+マウスホイールでフォントサイズ調整。
  - **相対タイムスタンプ**: 絶対時刻と最新ログからの相対時刻を切り替え可能。
  - **統計バー**: レベルごとのログ数（DEBUG/INFO/WARN/ERROR）と表示中/全ログ数を表示。
- ⚙️ **Project & Editor Settings**: プレフィックス、ログレベル、ファイルパスなどを Godot の設定メニューから直接管理。
- 🧩 **インスタンス単位の設定**: ネットワークやAIなど、特定のサブシステム向けに独自のプレフィックスやレベルを持つロガーを作成可能。
- 🧬 **ノードベースロガー**: `DLoggerNode` や `DLoggerFinder` ノードを使ってシーンツリーにロギングを統合。
- 🎨 **リッチテキスト出力**: エディタパネル上で BBCode をサポートし、クリック可能なファイル:行リンク、カテゴリフィルター、ネスト深さに応じたメッセージ括弧のレインボー色分けを提供。
- ⚡ **パフォーマンス重視**: ログレベルが無効な場合、複雑な文字列フォーマット処理を自動的にスキップ。時刻/フレーム値はディスパッチごとに1回だけ計算され、全ロガーで共有される。
- ⏱️ **パフォーマンス計測**: `benchmark()` で任意の処理を計測。通常は INFO（カテゴリ `PERF`）で記録され、スパイクしきい値（デフォルト 16ms）以上になると自動的に WARN へ格上げされる。
- 🛠️ **デバッグ専用設計**: コンソールおよびファイル出力はリリースビルドで自動的に無効化される。WARN/ERROR は `push_warning()`/`push_error()` を通じて伝達される。

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
# 出力例: [  1.234s][F:123][gameplay] [Player] - [DEBUG] プレイヤーがジャンプした
```

---

## ⚙️ 設定

設定は **Editor > Editor Settings > D-Logger** から管理する（該当する値は実行時に Project Settings と同期される）。`prefix` 設定は **Project > Project Settings > Debug > D-Logger** で設定する：

| 設定項目 | 型 | デフォルト値 | 保存先 | 説明 |
|---------|------|---------|----------|-------------|
| `prefix` | String | `"D-Logger"` | Project Setting | ログの共通プレフィックス。 |
| `enable_console_log` | Boolean | `false` | Editor Setting | コンソール出力を有効化（デバッグビルドのみ）。 |
| `min_log_level` | Enum | `DEBUG` | Editor Setting | 表示する最小レベル（DEBUG, INFO, WARN, ERROR）。 |
| `enable_file_log` | Boolean | `false` | Editor Setting | ファイルへのログ出力を有効化。 |
| `log_file_path` | String | `user://debug.log` | Editor Setting | ログファイルの保存先パス。 |
| `auto_activate_panel` | Boolean | `true` | Editor Setting | デバッグ開始時に D-Logger パネルを自動表示。 |
| `auto_clear_on_start` | Boolean | `true` | Editor Setting | デバッグセッション開始時にパネルを自動クリア。 |
| `pause_on_error` | Boolean | `false` | Editor Setting | ERROR ログ出力時にゲームを自動一時停止。 |
| `panel_font_size` | Integer | `14` | Editor Setting | パネルログ表示のフォントサイズ（Ctrl+マウスホイールで調整）。 |

---

## 🔧 インスタンスごとのロガー

特定のシステム専用のロガーが必要な場合は、個別のインスタンスを作成できる。コンストラクタはプレフィックス、最小ログレベル、コンソール上書き、ファイルパスを受け付ける：

```gdscript
var network_log: DLoggerClass

func _init():
    # DLoggerClass.new(prefix, min_level, console_enabled, file_path)
    network_log = DLoggerClass.new("NETWORK", DLoggerConstants.LogLevel.INFO)

func _ready():
    network_log.info("サーバーに接続中...")
```

### DLoggerNode（シーンベースロガー）

Autoload の `DLogger` は `DLoggerNode` であり、`ProjectSettings.settings_changed` を監視し、d_logger 関連の設定が変更されたときに自動再構成を行う。シーン内に `DLoggerNode` を配置し、`DLoggerInitParam` リソースのエクスポートで設定することも可能：

```
DLoggerNode (シーンツリー内)
  └─ DLoggerInitParam (エクスポート済み Resource)
       ├─ prefix_override
       ├─ min_level_override
       ├─ console_enabled_override
       └─ file_path_override
```

### DLoggerFinder（祖先＋兄弟ノード検索）

`DLoggerFinder` は `DLoggerFunc.find_logger_from_ancestor()` を使用してロガーを検索し、見つかったら `on_log_found(logger)` シグナルを発火する。検索は祖先チェーンを遡上しつつ、各レベルでその祖先の他の子（finder から見て uncle にあたる兄弟ロガー）も検査する。共有コンテナレイアウトで兄弟ノードにロガーがある場合に便利だが、より近い兄弟が遠い祖先より優先される点に注意。親や兄弟のロガー設定を継承したい場合に有用。

---

## 📖 API リファレンス

### ロギングメソッド

すべてのメソッドは `true` を返す。これにより、`assert()` 内で使用してデバッグ時のみ実行させることが可能だ。

| # | 引数 | 型 | デフォルト | 説明 |
|---|------|------|---------|-------------|
| 1 | `msg` | `String` | — | ログメッセージ。`{0}`, `{name}` プレースホルダー使用可 |
| 2 | `v` | `Variant` | `[]` | `String.format()` 用の値: Array, Dictionary, 単一値 |
| 3 | `cat` | `String` | `""` | フィルタリング用カテゴリ（パイプ区切り `"foo|bar"` 対応） |
| 4 | `ctx` | `Object` | `null` | コンテキストオブジェクト（通常は `self`） |
| 5 | `p` | `String` | `""` | この呼び出しのみのプレフィックス上書き |

```gdscript
debug(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
info(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
warn(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
error(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
```

これらのシグネチャは `DLoggerNode`, `DLoggerNodeBase`（転送メソッド）、およびすべての `DLoggerBase` サブクラスでも利用可能。（実装側にはディスパッチチェーンが使う内部引数 `p_caller_info: Variant = null` が追加で存在する。通常の呼び出しでは省略する。）

### レベルチェック
重い計算を伴うログ出力の前に使用すると効果的だ。

- `is_debug_enabled() -> bool`
- `is_info_enabled() -> bool`
- `is_warn_enabled() -> bool`
- `is_error_enabled() -> bool`

### ベンチマーク

任意の callable の実行時間を計測する。通常の結果は INFO（カテゴリ `PERF`）で記録され、スパイクしきい値以上になると代わりに WARN で記録される。callable の戻り値はそのまま返される。

```gdscript
# 基本的な使い方
var result: Variant = DLogger.benchmark("collision_update", func():
    return _update_collisions()
)

# スパイクしきい値のカスタマイズ（デフォルト: 16ms）
DLogger.benchmark("level_load", func(): _load_level(), 100.0)
```

`benchmark()` は同期実行のみを計測する — callable が yield すると即座に戻るため、`await` 区間は計測対象外。`DLoggerNode` と `DLoggerNodeBase`（フォワーディング）でも利用可能。

### DLoggerClass コンストラクタ

```gdscript
DLoggerClass.new(
    p_prefix: Variant = null,                      # プレフィックス上書き（null = ProjectSetting使用）
    p_min_lvl: int = NOT_SPECIFIED,                 # 最小レベルの上書き（-1 = ProjectSetting使用）
    p_console_enabled: Variant = null,               # コンソール出力の上書き（null = ProjectSetting使用）
    p_file_path: String = ""                        # ファイルパスの上書き（"" = ProjectSetting使用）
) -> DLoggerClass
```

### DLoggerInitParam Resource

`DLoggerNode` のインスペクタ設定用エクスポートリソース：

```gdscript
prefix_override: String
min_level_override: int
console_enabled_override: Variant  # null = ProjectSettings使用
file_path_override: String
```

### エディタパネルのショートカット

| ショートカット | 動作 |
|----------|--------|
| **Ctrl + L** | ログをクリア |
| **Ctrl + C** | 選択中（または表示中の全）ログをクリップボードにコピー |
| **Ctrl + Alt + S** | タイムスタンプ付きファイルとして `user://` に保存 |
| **Ctrl + F** | 検索ボックスにフォーカス |
| **Ctrl + マウスホイール** | フォントサイズ調整 |
| **1 / 2 / 3 / 4** | レベルフィルタ切替: DEBUG / INFO+ / WARN+ / ERROR |
| **Alt + Click**（カテゴリ） | そのカテゴリのみ表示（Solo） |
| **Escape** | 選択をクリア |
| **右ドラッグ** | ログビューをスクロール |
| **左ドラッグ** | 複数ログエントリを選択 |

---

## 📝 出力形式

ログは以下の形式で出力される：
```
[   time ][F:frame][source] [file:line] [context] - [LEVEL] message
```

カテゴリ未指定時はデフォルトプレフィックス（`D-Logger`）がラベルとして使われる：
```
[  1.234s][F:123][D-Logger] - [INFO] ゲームを開始した
```

カテゴリを指定すると、そのカテゴリがラベルになる（またはカスタムプレフィックスに追加される）：
```
[  1.234s][F:123][gameplay] [Player] - [DEBUG] キャラクタースポーン
```

カスタムプレフィックスとカテゴリ使用時：
```
[  1.234s][F:123][NETWORK:auth] [server.gd:42] - [WARN] 接続タイムアウト
```

**注意:** `[file:line]`（呼び出し元情報）は、パフォーマンス上の理由から **WARN** と **ERROR** レベルでのみ表示される — `get_stack()` は DEBUG/INFO では呼び出されない。

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

これはリリースビルドに対する最も強力な最適化でもある：Godot はリリースエクスポートで `assert()` 文を完全に取り除くため、呼び出し自体（引数の評価を含む）が一切コストにならない：

```gdscript
# 重い計算はリリースビルドでは決して実行されない
assert(DLogger.debug("複雑な計算結果: {0}", [do_heavy_calc()]))
```

デバッグビルドでは通常通りフォーマット・出力され、リリースビルドでは文ごと消える。

### パフォーマンスのボトルネック調査
`DLogger.benchmark()` で任意の関数を手軽に計測し、スパイクを自動通知できる：

```gdscript
var result := DLogger.benchmark("physics_step", func() -> float:
    return _run_physics()
)
```

### パイプ区切りカテゴリ
カテゴリは `|` で区切ることで複数タグを持たせ、多角的なフィルタリングが可能：

```gdscript
DLogger.info("試合が開始した", [], "match|player|combat", self)
```

各タグはエディタパネルのフィルターバーで個別のトグルボタンになる。

---

## 🐛 トラブルシューティング

### コンソールにログが表示されない
- プラグインが **Project Settings** で有効になっているか確認する。
- **Editor Settings** の `enable_console_log` が `true` になっているか確認する。
- `min_log_level`（最小ログレベル）の設定を確認する。
- 注意：D-Logger はデフォルトで **リリースビルドではコンソール/ファイル出力を行わない**（WARN/ERROR は `push_warning()`/`push_error()` を通じて伝達される）。

### ログファイルが作成されない
- 設定の `log_file_path` を確認する。
- デフォルトのパスは `user://debug.log` である。`user://` フォルダは、Godot エディタの **Project > Open User Data Folder** から開くことができる。
