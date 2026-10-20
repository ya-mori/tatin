import Foundation
import Testing

@testable import UsageKit

/// 決まった結果だけを返す取得元。通信せずに集約の挙動だけを見る。
private struct StubProvider: UsageProvider {
    let source: UsageSource
    let result: Result<UsageSnapshot, UsageError>

    func fetch() async throws -> UsageSnapshot {
        try result.get()
    }
}

private func snapshot(_ source: UsageSource, _ percent: Int) -> UsageSnapshot {
    UsageSnapshot(source: source, usedPercent: percent, detail: "", resetAt: nil)
}

@Suite("取得結果の集約")
struct UsageStoreTests {
    @Test("メニューバーには取得元ごとの残りを並べる")
    @MainActor
    func menuBarShowsEachSource() async {
        let store = UsageStore(providers: [
            StubProvider(source: .claude, result: .success(snapshot(.claude, 25))),
            StubProvider(source: .codex, result: .success(snapshot(.codex, 23))),
        ])

        await store.refresh()

        #expect(
            store.menuBarItems == [.init(source: .claude, text: "75%"), .init(source: .codex, text: "77%")])
        #expect(store.lastRefreshedAt != nil)
    }

    @Test("片方が失敗してももう片方は表示できる")
    @MainActor
    func partialFailureKeepsTheOther() async {
        let store = UsageStore(providers: [
            StubProvider(source: .claude, result: .failure(.unauthorized)),
            StubProvider(source: .codex, result: .success(snapshot(.codex, 23))),
        ])

        await store.refresh()

        #expect(store.entries.count == 2)
        #expect(store.entries.first?.error == .unauthorized)
        #expect(store.entries.first?.snapshot == nil)
        // 取れなかった側も並びから消さない。幅が変わって隣のアイコンが動くため。
        #expect(
            store.menuBarItems == [.init(source: .claude, text: "--"), .init(source: .codex, text: "77%")])
    }

    @Test("どれも取れなければ取得元ごとに印を出す")
    @MainActor
    func allFailuresShowPlaceholder() async {
        let store = UsageStore(providers: [
            StubProvider(source: .claude, result: .failure(.unauthorized)),
            StubProvider(source: .codex, result: .failure(.credentialsUnavailable("なし"))),
        ])

        await store.refresh()

        #expect(
            store.menuBarItems == [.init(source: .claude, text: "--"), .init(source: .codex, text: "--")])
    }

    @Test("まだ一度も取れていなくても並びの形は変えない")
    @MainActor
    func beforeFirstRefreshKeepsShape() {
        let store = UsageStore(providers: [])

        #expect(store.menuBarItems.map(\.source) == UsageSource.allCases)
        #expect(store.menuBarItems.allSatisfy { $0.text == "--" })
    }

    @Test("並びは取得の速さに左右されない")
    @MainActor
    func orderFollowsDefinitionNotArrival() async {
        // 与える順を入れ替えても、メニューの並びは UsageSource の定義順になる。
        let store = UsageStore(providers: [
            StubProvider(source: .codex, result: .success(snapshot(.codex, 23))),
            StubProvider(source: .claude, result: .success(snapshot(.claude, 25))),
        ])

        await store.refresh()

        #expect(store.entries.map(\.source) == [.claude, .codex])
    }
}
