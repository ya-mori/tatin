import Foundation
import Observation

/// 取得元ひとつぶんの結果。片方が失敗しても、もう片方は表示できるようにする。
public struct UsageEntry: Identifiable, Sendable {
    public let source: UsageSource
    public let result: Result<UsageSnapshot, UsageError>

    public init(source: UsageSource, result: Result<UsageSnapshot, UsageError>) {
        self.source = source
        self.result = result
    }

    public var id: UsageSource { source }

    public var snapshot: UsageSnapshot? {
        guard case .success(let snapshot) = result else { return nil }
        return snapshot
    }

    public var error: UsageError? {
        guard case .failure(let error) = result else { return nil }
        return error
    }
}

/// メニューバーに並べる 1 件ぶん。記号は取得元が、数字はその時の消化率が決める。
public struct MenuBarItem: Equatable, Sendable {
    public let source: UsageSource
    public let text: String

    public init(source: UsageSource, text: String) {
        self.source = source
        self.text = text
    }
}

/// すべての取得元をまとめて引き、画面に見せる状態を持つ。
@MainActor
@Observable
public final class UsageStore {
    public private(set) var entries: [UsageEntry] = []
    public private(set) var isRefreshing = false
    public private(set) var lastRefreshedAt: Date?

    private let providers: [any UsageProvider]
    private var autoRefreshTask: Task<Void, Never>?

    public init(providers: [any UsageProvider] = UsageStore.defaultProviders) {
        self.providers = providers
    }

    public static var defaultProviders: [any UsageProvider] {
        [ClaudeUsageProvider(), CodexUsageProvider()]
    }

    /// すべての取得元を同時に引き直す。
    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let providers = self.providers
        let fetched = await withTaskGroup(of: UsageEntry.self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        let snapshot = try await provider.fetch()
                        return UsageEntry(source: provider.source, result: .success(snapshot))
                    } catch let error as UsageError {
                        return UsageEntry(source: provider.source, result: .failure(error))
                    } catch {
                        return UsageEntry(
                            source: provider.source,
                            result: .failure(.transportFailed(error.localizedDescription))
                        )
                    }
                }
            }
            var collected: [UsageEntry] = []
            for await entry in group {
                collected.append(entry)
            }
            return collected
        }

        // 到着順でメニューの並びが入れ替わらないよう、定義順に戻す。
        entries = UsageSource.allCases.compactMap { source in
            fetched.first { $0.source == source }
        }
        lastRefreshedAt = Date()
    }

    /// 一定間隔で引き直し続ける。すでに動いていれば止めてから始める。
    public func startAutoRefresh(every interval: Duration) {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return  // キャンセルされた
                }
            }
        }
    }

    public func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    /// メニューバーに並べる中身。取得元ごとに記号ひとつと、残りの割合ひとつ。
    ///
    /// 取れなかった取得元も "--" で並びに残す。数が減ると幅が変わり、
    /// 隣のアイコンの位置まで動いてしまう。まだ一度も引けていないときも同じ。
    public var menuBarItems: [MenuBarItem] {
        guard !entries.isEmpty else {
            return UsageSource.allCases.map { MenuBarItem(source: $0, text: "--") }
        }
        return entries.map { entry in
            MenuBarItem(
                source: entry.source,
                text: entry.snapshot.map { "\($0.remainingPercent)%" } ?? "--"
            )
        }
    }
}
