//
//  Models.swift
//  Mac_Trade_Journalk
//
//  Data models for trades
//

import Foundation

// MARK: - Asset Classes

enum AssetClass: String, Codable, CaseIterable, Hashable {
    case forex = "Forex"
    case crypto = "Crypto"
}

// MARK: - Trade Models

struct ActiveTrade: Identifiable, Codable, Hashable {
    let id: UUID
    var assetClass: AssetClass
    var pairSymbol: String
    var risk: Double
    var openDate: Date
    var takeProfitPips: Double?
    
    init(id: UUID = UUID(), assetClass: AssetClass, pairSymbol: String, risk: Double, openDate: Date = Date(), takeProfitPips: Double? = nil) {
        self.id = id
        self.assetClass = assetClass
        self.pairSymbol = pairSymbol
        self.risk = risk
        self.openDate = openDate
        self.takeProfitPips = takeProfitPips
    }
}

struct ClosedTrade: Identifiable, Codable, Hashable {
    let id: UUID
    var assetClass: AssetClass
    var pairSymbol: String
    var risk: Double
    var openDate: Date
    var closeDate: Date
    var result: Double
    
    init(id: UUID = UUID(), assetClass: AssetClass, pairSymbol: String, risk: Double, openDate: Date, closeDate: Date, result: Double = 0) {
        self.id = id
        self.assetClass = assetClass
        self.pairSymbol = pairSymbol
        self.risk = risk
        self.openDate = openDate
        self.closeDate = closeDate
        self.result = result
    }
}

// MARK: - Trading Pairs

struct ForexPairs {
    static let groups: [String: [String]] = [
        "AUD": ["AUD/CAD","AUD/CHF","AUD/JPY","AUD/NZD","AUD/USD"],
        "CAD": ["CAD/CHF","CAD/JPY"],
        "CHF": ["CHF/JPY"],
        "EUR": ["EUR/AUD","EUR/CAD","EUR/CHF","EUR/GBP","EUR/JPY","EUR/NZD","EUR/USD"],
        "GBP": ["GBP/AUD","GBP/CAD","GBP/CHF","GBP/JPY","GBP/NZD","GBP/USD"],
        "JPY": ["JPY/CHF"],
        "NZD": ["NZD/CAD","NZD/CHF","NZD/JPY","NZD/USD"],
        "USD": ["USD/CAD","USD/CHF","USD/JPY"]
    ]
    
    static var baseKeysSorted: [String] {
        Array(groups.keys).sorted()
    }
}

struct CryptoMajors {
    static let pairs = [
        "BTC/USD", "ETH/USD", "BNB/USD", "SOL/USD", "XRP/USD", "ADA/USD",
        "AVAX/USD", "DOT/USD", "LINK/USD", "LTC/USD", "MATIC/USD", "DOGE/USD"
    ]
}

// MARK: - Metrics

struct SummaryMetrics {
    let totalClosed: Int
    let winTrades: Int
    let lossTrades: Int
    let winRate: Double
    let avgWin: Double
    let avgLoss: Double
    let largestWin: Double
    let largestLoss: Double
    let grossProfit: Double
    let grossLoss: Double
    let profitFactor: Double

    static func compute(from closed: [ClosedTrade]) -> SummaryMetrics {
        let total = closed.count
        let winners = closed.filter { $0.result > 0 }
        let losers  = closed.filter { $0.result < 0 }
        let winCount = winners.count
        let lossCount = losers.count
        let winRate = total > 0 ? Double(winCount)/Double(total) : 0
        let avgWin  = winCount > 0 ? winners.map(\.result).reduce(0,+)/Double(winCount) : 0
        let avgLoss = lossCount > 0 ? losers.map(\.result).reduce(0,+)/Double(lossCount) : 0
        let largestWin  = winners.map(\.result).max() ?? 0
        let largestLoss = losers.map(\.result).min() ?? 0
        let grossProfit = winners.map(\.result).reduce(0,+)
        let grossLoss   = abs(losers.map(\.result).reduce(0,+))
        let profitFactor = grossLoss == 0 ? (grossProfit > 0 ? .infinity : 0) : grossProfit / grossLoss
        
        return .init(
            totalClosed: total,
            winTrades: winCount,
            lossTrades: lossCount,
            winRate: winRate,
            avgWin: avgWin,
            avgLoss: avgLoss,
            largestWin: largestWin,
            largestLoss: largestLoss,
            grossProfit: grossProfit,
            grossLoss: grossLoss,
            profitFactor: profitFactor
        )
    }
}
