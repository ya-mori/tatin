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
    @Test("メニューバーには最も進んでいる消化率を出す")
    @MainActor
    func highestPercentWins() async {
        let store = UsageStore(providers: [
            StubProvider(source: .claude, result: .success(snapshot(.claude, 25))),
            StubProvider(source: .codex, result: .success(snapshot(.codex, 23))),
        ])

        await store.refresh()

        #expect(store.highestUsedPercent == 23)
        #expect(store.menuBarTitle == "23%")
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
        #expect(store.highestUsedPercent == 23)
    }

    @Test("どれも取れなければ数字を出さない")
    @MainActor
    func allFailuresShowPlaceholder() async {
        let store = UsageStore(providers: [
            StubProvider(source: .claude, result: .failure(.unauthorized)),
            StubProvider(source: .codex, result: .failure(.credentialsUnavailable("なし"))),
        ])

        await store.refresh()

        #expect(store.highestUsedPercent == nil)
        #expect(store.menuBarTitle == "--")
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
