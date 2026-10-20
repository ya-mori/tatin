# tatin

自前の macOS ツールをまとめて置くモノレポ。メニューバー常駐アプリなどを
ひとつの SwiftPM パッケージで管理する。

## 必要なもの

- macOS 14 以上
- Command Line Tools for Xcode（**Xcode 本体は不要**）
- [mise](https://mise.jdx.dev/)

## はじめかた

```sh
mise trust            # 初回のみ。これを忘れると mise.toml のタスクが認識されない
mise run doctor       # ビルド環境に既知の壊れ方がないか診断する
mise run start MenuBar
```

`start` はビルドして `.app` にまとめ、起動し直すところまでやる。
メニューバーにアイコンが出れば成功。

## アプリ

| アプリ | 内容 |
| --- | --- |
| `MenuBar` | 足場の確認用。バージョンの表示とログイン項目の切り替えだけを持つ |
| `Usage` | Claude と Codex の月次クレジット消化率をメニューバーに出す |

### Usage

```sh
mise run start Usage
```

メニューバーには取得元ごとに記号と、上限に対する残りの割合を並べる。記号はそれぞれのロゴに
形が近い SF Symbols（Claude は `asterisk`、Codex は `camera.aperture`）。
押すと内訳とリセットまでの残りが出る。

値は Claude Code の `/usage` や Codex が参照しているのと同じ API から引く。
認証には本体が置いた OAuth トークンを使うため、**Claude Code と Codex CLI に
それぞれログイン済みであること**が前提。片方が未ログインでも、もう片方は表示する。

Claude のトークンはキーチェーンにあるため、初回の起動で許可を聞かれる。
「常に許可」を選ぶ。ad-hoc 署名はビルドの内容が変わると署名も変わるので、
作り直したあとに再び聞かれることがある。

## タスク

`mise tasks ls` で一覧できる。

| コマンド | 内容 |
| --- | --- |
| `mise run build` | 全ターゲットをビルドする |
| `mise run test` | テストを実行する |
| `mise run fmt` | ソースを整形する |
| `mise run lint` | 整形崩れを検査する（崩れていれば失敗する） |
| `mise run check` | lint・build・test をまとめて実行する |
| `mise run start <アプリ名>` | ビルドして `.app` を起動し直す |
| `mise run bundle <アプリ名>` | `.app` にまとめて署名する |
| `mise run bundle-all` | Apps 配下の全アプリを `.app` にまとめる |
| `mise run install <アプリ名>` | `~/Applications` に配置する |
| `mise run new-app <アプリ名>` | 新しいアプリを雛形から追加する |
| `mise run doctor` | ビルド環境を診断する |
| `mise run clean` | ビルド成果物と `.app` を削除する |

## 新しいアプリを足す

```sh
mise run new-app Clipboard
mise run start Clipboard
```

`Apps/Clipboard/` の雛形と `Package.swift` のターゲットが作られる。

アプリアイコンを付けるには `Apps/<アプリ名>/Bundle/AppIcon.icns` を置く。
`bundle` が `.app` に入れる（Info.plist の `CFBundleIconFile` は雛形に入っている）。

## 構成

```
Apps/<アプリ名>/
  Sources/            Swift のソース
  Bundle/Info.plist   .app に埋め込む情報（LSUIElement など）
Libraries/TatinKit/   全アプリ共通のコード
Libraries/UsageKit/   使用率の取得（Usage が使う）
Tests/                テスト
mise-tasks/           引数を取るタスク（mise.toml からは分離）
```

## 決めごと

- **テストは swift-testing（`import Testing`）で書く。**
  Command Line Tools には XCTest が含まれず、`import XCTest` は Xcode が無いと通らない。
- **動作確認は `.app` として起動して行う。**
  `swift run` では Info.plist を読まないため、メニューバーに出ず、
  ログイン項目の登録も失敗する。
- **`.app` は ad-hoc 署名。**
  手元で動かす分には問題ない。配布するときは `TATIN_CODESIGN_IDENTITY` に
  署名 ID を渡す。
- **使用率は取得元の API から引く。セッションログからは計算しない。**
  ローカルのログを定価で積み上げてみたところ、実際の請求額と 2.6 倍ずれた。
  Codex 側は Business プランだとログの `rate_limits` が空になり、そもそも使えない。
- **ビルドが通らないときはまず `mise run doctor`。**
  Command Line Tools は入れ直したときに古いファイルが残ることがあり、
  `import Foundation` すら通らなくなる、`swift test` だけが落ちる、といった
  エラーからは原因の分かりにくい壊れ方をする。
