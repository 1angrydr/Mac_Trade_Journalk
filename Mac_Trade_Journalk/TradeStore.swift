//
//  TradeStore.swift
//  Mac_Trade_Journalk
//
//  Trade data store with CloudKit sync
//

import Foundation
import SwiftUI
import Combine

final class TradeStore: ObservableObject {
    @AppStorage("EZPZ.activeTrades") private var activeJSON: String = "[]"
    @AppStorage("EZPZ.closedTrades") private var closedJSON: String = "[]"
    
    @Published var activeTrades: [ActiveTrade] = []
    @Published var closedTrades: [ClosedTrade] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: String = "Not synced"

    init() {
        load()
        Task {
            await pullFromCloud()
        }
    }

    func load() {
        if let d = activeJSON.data(using: .utf8),
           let arr = try? JSONDecoder().decode([ActiveTrade].self, from: d) {
            activeTrades = arr
        } else {
            activeTrades = []
        }
        
        if let d = closedJSON.data(using: .utf8),
           let arr = try? JSONDecoder().decode([ClosedTrade].self, from: d) {
            closedTrades = arr
        } else {
            closedTrades = []
        }
    }
    
    func save() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.withoutEscapingSlashes]
        
        if let d = try? enc.encode(activeTrades), let s = String(data: d, encoding: .utf8) {
            activeJSON = s
        }
        
        if let d = try? enc.encode(closedTrades), let s = String(data: d, encoding: .utf8) {
            closedJSON = s
        }
        
        Task {
            await pushToCloud()
        }
    }

    func addActive(_ t: ActiveTrade) {
        activeTrades.append(t)
        save()
    }
    
    func updateActive(_ updated: ActiveTrade) {
        if let i = activeTrades.firstIndex(where: {$0.id == updated.id}) {
            activeTrades[i] = updated
            save()
        }
    }
    
    func deleteActive(id: UUID) {
        activeTrades.removeAll { $0.id == id }
        save()
        
        Task {
            try? await CloudKitService.shared.deleteActiveTrade(id)
        }
    }

    func close(_ t: ActiveTrade, at closeDate: Date, result: Double) {
        activeTrades.removeAll { $0.id == t.id }
        let closedTrade = ClosedTrade(
            id: t.id,
            assetClass: t.assetClass,
            pairSymbol: t.pairSymbol,
            risk: t.risk,
            openDate: t.openDate,
            closeDate: closeDate,
            result: result
        )
        closedTrades.append(closedTrade)
        save()
        
        Task {
            do {
                try await CloudKitService.shared.deleteActiveTrade(t.id)
                _ = try await CloudKitService.shared.saveClosedTrade(closedTrade)
            } catch {
                print("Error closing trade in CloudKit: \(error)")
            }
        }
    }
    
    func updateClosed(_ updated: ClosedTrade) {
        if let i = closedTrades.firstIndex(where: {$0.id == updated.id}) {
            closedTrades[i] = updated
            save()
        }
    }
    
    func deleteClosed(id: UUID) {
        closedTrades.removeAll { $0.id == id }
        save()
        
        Task {
            try? await CloudKitService.shared.deleteClosedTrade(id)
        }
    }

    func resetAll() {
        let activeIDs = activeTrades.map { $0.id }
        let closedIDs = closedTrades.map { $0.id }
        
        activeTrades.removeAll()
        closedTrades.removeAll()
        save()
        
        Task {
            for id in activeIDs {
                try? await CloudKitService.shared.deleteActiveTrade(id)
            }
            for id in closedIDs {
                try? await CloudKitService.shared.deleteClosedTrade(id)
            }
        }
    }
    
    @MainActor
    func pushToCloud() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncStatus = "Syncing to iCloud..."
        defer { isSyncing = false }
        
        do {
            try await CloudKitService.shared.syncToCloud(activeTrades: activeTrades, closedTrades: closedTrades)
            lastSyncDate = Date()
            syncStatus = "✅ Synced to iCloud"
        } catch {
            print("Push to cloud failed: \(error)")
            syncStatus = "❌ Sync failed"
        }
    }
    
    @MainActor
    func pullFromCloud() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncStatus = "Syncing from iCloud..."
        defer { isSyncing = false }
        
        do {
            let (cloudActive, cloudClosed) = try await CloudKitService.shared.syncFromCloud()
            
            activeTrades = cloudActive
            closedTrades = cloudClosed
            
            let enc = JSONEncoder()
            enc.outputFormatting = [.withoutEscapingSlashes]
            
            if let d = try? enc.encode(activeTrades), let s = String(data: d, encoding: .utf8) {
                activeJSON = s
            }
            
            if let d = try? enc.encode(closedTrades), let s = String(data: d, encoding: .utf8) {
                closedJSON = s
            }
            
            lastSyncDate = Date()
            syncStatus = "✅ Synced from iCloud"
        } catch {
            print("Pull from cloud failed: \(error)")
            syncStatus = "❌ Sync failed"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let transferForexToJournal = Notification.Name("transferForexToJournal")
    static let transferCryptoToJournal = Notification.Name("transferCryptoToJournal")
    static let switchToJournalTab = Notification.Name("switchToJournalTab")
}
