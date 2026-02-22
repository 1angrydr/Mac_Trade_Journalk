//
//  TradeStore.swift
//  Mac_Trade_Journalk
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class TradeStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var activeTrades: [ActiveTrade] = []
    @Published private(set) var closedTrades: [ClosedTrade] = []
    @Published private(set) var syncStatus: String = "Not synced"
    @Published private(set) var isSyncing: Bool = false

    // MARK: - Persistence Keys

    private let activeKey  = "mac.tradejournal.activeTrades"
    private let closedKey  = "mac.tradejournal.closedTrades"
    private let encoder    = JSONEncoder()
    private let decoder    = JSONDecoder()

    // MARK: - Init

    init() {
        load()
        Task { await pullFromCloud() }
    }

    // MARK: - Load / Save

    private func load() {
        if let data = UserDefaults.standard.data(forKey: activeKey),
           let trades = try? decoder.decode([ActiveTrade].self, from: data) {
            activeTrades = trades
        }
        if let data = UserDefaults.standard.data(forKey: closedKey),
           let trades = try? decoder.decode([ClosedTrade].self, from: data) {
            closedTrades = trades
        }
    }

    private func persist() {
        if let data = try? encoder.encode(activeTrades) {
            UserDefaults.standard.set(data, forKey: activeKey)
        }
        if let data = try? encoder.encode(closedTrades) {
            UserDefaults.standard.set(data, forKey: closedKey)
        }
    }

    // MARK: - Active Trade Operations

    func addActive(_ trade: ActiveTrade) {
        activeTrades.append(trade)
        persist()
        Task { try? await CloudKitService.shared.saveActiveTrade(trade) }
    }

    func updateActive(_ trade: ActiveTrade) {
        guard let i = activeTrades.firstIndex(where: { $0.id == trade.id }) else { return }
        activeTrades[i] = trade
        persist()
        Task { try? await CloudKitService.shared.saveActiveTrade(trade) }
    }

    func deleteActive(id: UUID) {
        activeTrades.removeAll { $0.id == id }
        persist()
        Task { try? await CloudKitService.shared.deleteActiveTrade(id) }
    }

    // MARK: - Close Trade

    func close(_ trade: ActiveTrade, at closeDate: Date, result: Double) {
        activeTrades.removeAll { $0.id == trade.id }
        let closed = ClosedTrade(
            id: trade.id,
            assetClass: trade.assetClass,
            pairSymbol: trade.pairSymbol,
            risk: trade.risk,
            openDate: trade.openDate,
            closeDate: closeDate,
            result: result
        )
        closedTrades.append(closed)
        persist()
        Task {
            try? await CloudKitService.shared.deleteActiveTrade(trade.id)
            try? await CloudKitService.shared.saveClosedTrade(closed)
        }
    }

    // MARK: - Closed Trade Operations

    func updateClosed(_ trade: ClosedTrade) {
        guard let i = closedTrades.firstIndex(where: { $0.id == trade.id }) else { return }
        closedTrades[i] = trade
        persist()
        Task { try? await CloudKitService.shared.saveClosedTrade(trade) }
    }

    func deleteClosed(id: UUID) {
        closedTrades.removeAll { $0.id == id }
        persist()
        Task { try? await CloudKitService.shared.deleteClosedTrade(id) }
    }

    func resetAll() {
        let activeIDs = activeTrades.map(\.id)
        let closedIDs = closedTrades.map(\.id)
        activeTrades.removeAll()
        closedTrades.removeAll()
        persist()
        Task {
            for id in activeIDs  { try? await CloudKitService.shared.deleteActiveTrade(id) }
            for id in closedIDs  { try? await CloudKitService.shared.deleteClosedTrade(id) }
        }
    }

    // MARK: - Cloud Sync

    func pullFromCloud() async {
        guard !isSyncing else { return }
        isSyncing  = true
        syncStatus = "Syncing from iCloud…"
        // Do the network work on a background executor so the
        // main actor (and all UI) stays fully responsive.
        do {
            let (active, closed) = try await Task.detached(priority: .background) {
                try await CloudKitService.shared.syncFromCloud()
            }.value
            // Back on MainActor now — safe to update @Published state
            activeTrades = active
            closedTrades = closed
            persist()
            syncStatus = "✅ Synced"
        } catch {
            syncStatus = "⚠️ iCloud unavailable — using local data"
        }
        isSyncing = false
    }

    func pushToCloud() async {
        guard !isSyncing else { return }
        isSyncing = true
        // Snapshot values before leaving MainActor
        let activeSnapshot = activeTrades
        let closedSnapshot = closedTrades
        do {
            try await Task.detached(priority: .background) {
                try await CloudKitService.shared.syncToCloud(
                    activeTrades: activeSnapshot,
                    closedTrades: closedSnapshot
                )
            }.value
            syncStatus = "✅ Synced"
        } catch {
            syncStatus = "⚠️ Sync failed"
        }
        isSyncing = false
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let switchToJournalTab = Notification.Name("switchToJournalTab")
}
