# CLAUDE.md

tatin — 自前の macOS ツールを置くモノレポ。

## 作業を始める前に

- `mise trust` を済ませる。未 trust だと `mise.toml` の `[tasks]` が
  認識されず「no task found」になる（エラーに理由が出ないので気づきにくい）。
- ビルドや `swift test` が通らないときは、コードを疑う前に `mise run doctor`。

## 操作は mise に集約する

Makefile は使わない。`mise tasks ls` が操作の一覧。

新しい操作を足すときは、

- 引数を取らないもの → `mise.toml` の `[tasks]` に書く
- 引数を取るもの → `mise-tasks/` のスクリプトにする

インラインタスクは `$@` が展開されず、引数がコマンドの末尾に付くだけなので、
アプリ名などを受け取るタスクはスクリプト側に置く。

## このリポジトリの制約

- **テストは swift-testing（`import Testing`）で書く。**
  Command Line Tools には XCTest が含まれないため `import XCTest` は通らない。
- **アプリの確認は `mise run start <アプリ名>` で行う。**
  `swift run` では Info.plist を読まないため、メニューバーに出ず、
  `SMAppService` によるログイン項目の登録も失敗する。
- **`Package.swift` のマーカー行を消さない。**
  `mise run new-app` が `tatin:products` と `tatin:targets` の行を目印に
  ターゲットを追記する。

## シェルスクリプトを書くとき

変数展開の直後に全角文字を置かない。

```sh
echo "started: $app（確認してください）"    # NG: 全角まで変数名として読まれる
echo "started: ${app}（確認してください）"  # OK
```
