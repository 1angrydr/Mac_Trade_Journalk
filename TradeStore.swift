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

    // MARK: - Persistence Keys

    private let activeKey  = "mac.tradejournal.activeTrades"
    private let closedKey  = "mac.tradejournal.closedTrades"
    private let encoder    = JSONEncoder()
    private let decoder    = JSONDecoder()

    // MARK: - Init

    init() {
        load()
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
    }

    func updateActive(_ trade: ActiveTrade) {
        guard let i = activeTrades.firstIndex(where: { $0.id == trade.id }) else { return }
        activeTrades[i] = trade
        persist()
    }

    func deleteActive(id: UUID) {
        activeTrades.removeAll { $0.id == id }
        persist()
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
    }

    // MARK: - Closed Trade Operations

    func updateClosed(_ trade: ClosedTrade) {
        guard let i = closedTrades.firstIndex(where: { $0.id == trade.id }) else { return }
        closedTrades[i] = trade
        persist()
    }

    func deleteClosed(id: UUID) {
        closedTrades.removeAll { $0.id == id }
        persist()
    }

    func resetAll() {
        activeTrades.removeAll()
        closedTrades.removeAll()
        persist()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let switchToJournalTab = Notification.Name("switchToJournalTab")
}
