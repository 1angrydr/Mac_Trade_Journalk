//
//  CloudKitService.swift
//  Mac_Trade_Journalk
//
//  CloudKit sync service
//

import Foundation
import CloudKit
import os

final class CloudKitService {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let database: CKDatabase
    private let logger = Logger(subsystem: "net.fmpublishing.Mac-Trade-Journalk", category: "CloudKit")
    
    private init() {
        container = CKContainer(identifier: "iCloud.net.fmpublishing.Mac-Trade-Journalk")
        database = container.privateCloudDatabase
        logger.info("CloudKit initialized with container: iCloud.net.fmpublishing.Mac-Trade-Journalk")
    }
    
    func checkAccountStatus() async throws -> CKAccountStatus {
        let status = try await container.accountStatus()
        logger.info("CloudKit account status: \(String(describing: status))")
        return status
    }
    
    // MARK: - Active Trades
    
    func saveActiveTrade(_ trade: ActiveTrade) async throws -> CKRecord {
        let record = CKRecord(recordType: "ActiveTrade", recordID: CKRecord.ID(recordName: trade.id.uuidString))
        record["id"] = trade.id.uuidString
        record["assetClass"] = trade.assetClass.rawValue
        record["pairSymbol"] = trade.pairSymbol
        record["risk"] = trade.risk
        record["openDate"] = trade.openDate
        record["takeProfitPips"] = trade.takeProfitPips
        
        logger.info("Saving active trade: \(trade.pairSymbol)")
        let saved = try await database.save(record)
        logger.info("Successfully saved active trade")
        return saved
    }
    
    func fetchActiveTrades() async throws -> [ActiveTrade] {
        let query = CKQuery(recordType: "ActiveTrade", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "openDate", ascending: false)]
        
        logger.info("Fetching active trades from CloudKit...")
        let results = try await database.records(matching: query)
        
        let trades = results.matchResults.compactMap { _, result -> ActiveTrade? in
            guard let record = try? result.get(),
                  let idString = record["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let assetClassRaw = record["assetClass"] as? String,
                  let assetClass = AssetClass(rawValue: assetClassRaw),
                  let pairSymbol = record["pairSymbol"] as? String,
                  let risk = record["risk"] as? Double,
                  let openDate = record["openDate"] as? Date else {
                return nil
            }
            let takeProfitPips = record["takeProfitPips"] as? Double
            return ActiveTrade(id: id, assetClass: assetClass, pairSymbol: pairSymbol, risk: risk, openDate: openDate, takeProfitPips: takeProfitPips)
        }
        
        logger.info("Fetched \(trades.count) active trades")
        return trades
    }
    
    func deleteActiveTrade(_ id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        logger.info("Deleting active trade: \(id.uuidString)")
        try await database.deleteRecord(withID: recordID)
        logger.info("Successfully deleted active trade")
    }
    
    // MARK: - Closed Trades
    
    func saveClosedTrade(_ trade: ClosedTrade) async throws -> CKRecord {
        let record = CKRecord(recordType: "ClosedTrade", recordID: CKRecord.ID(recordName: trade.id.uuidString))
        record["id"] = trade.id.uuidString
        record["assetClass"] = trade.assetClass.rawValue
        record["pairSymbol"] = trade.pairSymbol
        record["risk"] = trade.risk
        record["openDate"] = trade.openDate
        record["closeDate"] = trade.closeDate
        record["result"] = trade.result
        
        logger.info("Saving closed trade: \(trade.pairSymbol)")
        let saved = try await database.save(record)
        logger.info("Successfully saved closed trade")
        return saved
    }
    
    func fetchClosedTrades() async throws -> [ClosedTrade] {
        let query = CKQuery(recordType: "ClosedTrade", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "closeDate", ascending: false)]
        
        logger.info("Fetching closed trades from CloudKit...")
        let results = try await database.records(matching: query)
        
        let trades = results.matchResults.compactMap { _, result -> ClosedTrade? in
            guard let record = try? result.get(),
                  let idString = record["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let assetClassRaw = record["assetClass"] as? String,
                  let assetClass = AssetClass(rawValue: assetClassRaw),
                  let pairSymbol = record["pairSymbol"] as? String,
                  let risk = record["risk"] as? Double,
                  let openDate = record["openDate"] as? Date,
                  let closeDate = record["closeDate"] as? Date,
                  let result = record["result"] as? Double else {
                return nil
            }
            return ClosedTrade(id: id, assetClass: assetClass, pairSymbol: pairSymbol, risk: risk, openDate: openDate, closeDate: closeDate, result: result)
        }
        
        logger.info("Fetched \(trades.count) closed trades")
        return trades
    }
    
    func deleteClosedTrade(_ id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        logger.info("Deleting closed trade: \(id.uuidString)")
        try await database.deleteRecord(withID: recordID)
        logger.info("Successfully deleted closed trade")
    }
    
    // MARK: - Sync
    
    func syncToCloud(activeTrades: [ActiveTrade], closedTrades: [ClosedTrade]) async throws {
        logger.info("Starting sync to cloud: \(activeTrades.count) active, \(closedTrades.count) closed")
        
        for trade in activeTrades {
            do {
                _ = try await saveActiveTrade(trade)
            } catch {
                logger.error("Failed to save active trade \(trade.id): \(error.localizedDescription)")
            }
        }
        
        for trade in closedTrades {
            do {
                _ = try await saveClosedTrade(trade)
            } catch {
                logger.error("Failed to save closed trade \(trade.id): \(error.localizedDescription)")
            }
        }
        
        logger.info("Sync to cloud completed")
    }
    
    func syncFromCloud() async throws -> ([ActiveTrade], [ClosedTrade]) {
        logger.info("Starting sync from cloud")
        
        async let activeTrades = fetchActiveTrades()
        async let closedTrades = fetchClosedTrades()
        
        let (active, closed) = try await (activeTrades, closedTrades)
        
        logger.info("Sync from cloud completed: \(active.count) active, \(closed.count) closed")
        return (active, closed)
    }
}
