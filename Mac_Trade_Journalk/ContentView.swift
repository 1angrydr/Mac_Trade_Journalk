//
//  ContentView.swift
//  Mac_Trade_Journalk
//
//  VIEWS ONLY - Works with separate files
//
import SwiftUI
import Combine

// This file contains ONLY UI components
// All data/logic is in separate files:
// - AnthropicConfig.swift (API config)
// - Models.swift (data models)
// - Theme.swift (styling)
// - CloudKitService.swift (iCloud sync)
// - TradeStore.swift (data management)

// MARK: - Crypto Calculator

struct CryptoCalculatorTab: View {
    @EnvironmentObject var store: TradeStore
    @State private var selectedPair: String = "BTC/USD"
    @State private var entryPriceText: String = ""
    @State private var stopLossText: String = ""
    @State private var riskAmount: String = ""
    @State private var leverageText: String = "1"
    @State private var positionUnits: Double? = nil
    @State private var positionNotional: Double? = nil
    @State private var stopDistance: Double? = nil
    @State private var isTransferring = false
    @State private var showEntryPricePopup = false
    @State private var showStopLossPopup = false
    @State private var showRiskAmountPopup = false
    @State private var showLeveragePopup = false

    private let cryptoPairs = CryptoMajors.pairs

    var baseCrypto: String { String(selectedPair.prefix(3)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("₿ Crypto Unit Calculator").font(titleFont)

                    GroupBox("Instrument") {
                        Picker("Crypto Pair", selection: $selectedPair) {
                            ForEach(cryptoPairs, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }

                    GroupBox("Position Parameters") {
                        VStack(alignment: .leading, spacing: 12) {

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Entry Price ($):").font(bodyFont)
                                Button { showEntryPricePopup = true } label: {
                                    HStack {
                                        Text(entryPriceText.isEmpty ? "e.g. 1977" : "$\(entryPriceText)")
                                            .foregroundColor(entryPriceText.isEmpty ? .secondary : .primary)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stop Loss Price ($):").font(bodyFont)
                                Button { showStopLossPopup = true } label: {
                                    HStack {
                                        Text(stopLossText.isEmpty ? "e.g. 1944" : "$\(stopLossText)")
                                            .foregroundColor(stopLossText.isEmpty ? .secondary : .primary)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Risk Amount ($):").font(bodyFont)
                                Button { showRiskAmountPopup = true } label: {
                                    HStack {
                                        Text(riskAmount.isEmpty ? "e.g. 100" : "$\(riskAmount)").foregroundColor(riskAmount.isEmpty ? .secondary : .primary)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Leverage:").font(bodyFont)
                                Button { showLeveragePopup = true } label: {
                                    HStack {
                                        Text(leverageText.isEmpty ? "1" : "\(leverageText)x").foregroundColor(leverageText.isEmpty ? .secondary : .primary)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                                Text("Common: 1x, 5x, 10x, 20x").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button(action: calculatePosition) {
                            Text("Calculate").font(subtitleFont).padding().frame(maxWidth: .infinity)
                        }.background(Color.orange.opacity(0.85)).foregroundColor(.white).cornerRadius(10)
                         .disabled(entryPriceText.isEmpty || stopLossText.isEmpty || riskAmount.isEmpty)

                        Button(action: resetAll) {
                            Text("Reset").font(subtitleFont).padding().frame(maxWidth: .infinity)
                        }.background(Color.gray.opacity(0.7)).foregroundColor(.white).cornerRadius(10)

                        Button(action: transferToJournal) {
                            if isTransferring {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).frame(maxWidth: .infinity).padding()
                            } else {
                                Text("Add to Journal").font(subtitleFont).padding().frame(maxWidth: .infinity)
                            }
                        }.background(Color.green.opacity(0.85)).foregroundColor(.white).cornerRadius(10).disabled(positionUnits == nil || isTransferring)
                    }

                    if let units = positionUnits, let notional = positionNotional, let dist = stopDistance {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Position Size: **\(String(format: "%.4f", units)) \(baseCrypto)**").font(subtitleFont)
                                Text("Stop Distance: **$\(String(format: "%.2f", dist))**").font(subtitleFont)
                                Text("Position Value: **$\(String(format: "%.2f", notional))**").font(subtitleFont)
                                if let lev = Double(leverageText), lev > 1 {
                                    let margin = notional / lev
                                    Text("Margin Required: **$\(String(format: "%.2f", margin))** (at \(String(format: "%.0f", lev))x leverage)").font(subtitleFont)
                                }
                            }
                        }
                    }
                }.padding(18)
            }.navigationTitle("Crypto Calculator")
        }
        .sheet(isPresented: $showEntryPricePopup) { NumericPopupField(title: "Entry Price ($)", valueText: $entryPriceText) }
        .sheet(isPresented: $showStopLossPopup) { NumericPopupField(title: "Stop Loss Price ($)", valueText: $stopLossText) }
        .sheet(isPresented: $showRiskAmountPopup) { NumericPopupField(title: "Risk Amount ($)", valueText: $riskAmount) }
        .sheet(isPresented: $showLeveragePopup) { NumericPopupField(title: "Leverage", valueText: $leverageText) }
    }

    func resetAll() {
        entryPriceText = ""
        stopLossText = ""
        riskAmount = ""
        leverageText = "1"
        positionUnits = nil
        positionNotional = nil
        stopDistance = nil
    }

    func calculatePosition() {
        guard let entry = Double(entryPriceText),
              let stop = Double(stopLossText),
              let risk = Double(riskAmount),
              let leverage = Double(leverageText),
              entry > 0, stop > 0, risk > 0, leverage > 0 else {
            positionUnits = nil; positionNotional = nil; stopDistance = nil; return
        }
        let dist = abs(entry - stop)
        guard dist > 0 else { positionUnits = nil; positionNotional = nil; stopDistance = nil; return }
        stopDistance = dist
        let units = (risk * leverage) / dist
        positionUnits = units
        positionNotional = units * entry
    }

    func transferToJournal() {
        guard let risk = Double(riskAmount), risk > 0 else { return }
        isTransferring = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            store.addActive(.init(assetClass: .crypto, pairSymbol: selectedPair, risk: risk, openDate: Date(), takeProfitPips: nil))
            NotificationCenter.default.post(name: .switchToJournalTab, object: nil)
            isTransferring = false
        }
    }
}

// MARK: - Forex Calculator

struct ForexCalculatorTab: View {
    @EnvironmentObject var store: TradeStore
    @State private var selectedBase = "EUR"
    @State private var selectedPair = "EUR/USD"
    @State private var accountBalanceText: String = ""
    @State private var riskPercentText: String = ""
    @State private var entryPriceText: String = ""
    @State private var stopLossPipsText: String = ""
    @State private var takeProfitPipsText: String = ""
    @State private var positionSize: Double? = nil
    @State private var moneyRisked: Double? = nil
    @State private var isTransferring = false
    @State private var showAccountBalancePopup = false
    @State private var showRiskPercentPopup = false
    @State private var showEntryPricePopup = false
    @State private var showStopLossPipsPopup = false
    @State private var showTakeProfitPipsPopup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("💱 Forex Pip Calculator").font(titleFont)
                    GroupBox("Select Pair") {
                        VStack(spacing: 8) {
                            Picker("Base Currency", selection: $selectedBase) {
                                ForEach(ForexPairs.baseKeysSorted, id: \.self) { Text($0).tag($0) }
                            }.pickerStyle(.menu)
                            Picker("Pair", selection: $selectedPair) {
                                ForEach(ForexPairs.groups[selectedBase] ?? [], id: \.self) { Text($0).tag($0) }
                            }.pickerStyle(.menu)
                        }
                    }
                    GroupBox("Account Parameters") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account Balance ($):").font(bodyFont)
                                Button { showAccountBalancePopup = true } label: {
                                    HStack {
                                        Text(accountBalanceText.isEmpty ? "e.g. 10000" : "$\(accountBalanceText)").foregroundColor(accountBalanceText.isEmpty ? .secondary : .primary)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Risk % Per Trade:").font(bodyFont)
                                Button { showRiskPercentPopup = true } label: {
                                    HStack {
                                        Text(riskPercentText.isEmpty ? "e.g. 1" : "\(riskPercentText)%").foregroundColor(riskPercentText.isEmpty ? .secondary : .primary)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                                Text("Typically 1-3%").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    GroupBox("Trade Parameters") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Entry Price:").font(bodyFont)
                                Button { showEntryPricePopup = true } label: {
                                    HStack {
                                        Text(entryPriceText.isEmpty ? "e.g. 1.0850" : entryPriceText).foregroundColor(entryPriceText.isEmpty ? .secondary : .primary)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stop Loss (pips):").font(bodyFont)
                                Button { showStopLossPipsPopup = true } label: {
                                    HStack {
                                        Text(stopLossPipsText.isEmpty ? "e.g. 20" : "\(stopLossPipsText) pips").foregroundColor(stopLossPipsText.isEmpty ? .secondary : .red)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Take Profit (Optional):").font(bodyFont)
                                Button { showTakeProfitPipsPopup = true } label: {
                                    HStack {
                                        Text(takeProfitPipsText.isEmpty ? "e.g. 50" : "\(takeProfitPipsText) pips").foregroundColor(takeProfitPipsText.isEmpty ? .secondary : .green)
                                        Spacer()
                                    }.padding(8).background(Color.secondarySystemGroupedBackground).cornerRadius(8)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        Button(action: calculatePosition) {
                            Text("Calculate").font(subtitleFont).padding().frame(maxWidth: .infinity)
                        }.background(Color.orange.opacity(0.85)).foregroundColor(.white).cornerRadius(10)
                         .disabled(accountBalanceText.isEmpty || riskPercentText.isEmpty || entryPriceText.isEmpty || stopLossPipsText.isEmpty)
                        Button(action: transferToJournal) {
                            if isTransferring {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).frame(maxWidth: .infinity).padding()
                            } else {
                                Text("Add to Journal").font(subtitleFont).padding().frame(maxWidth: .infinity)
                            }
                        }.background(Color.green.opacity(0.85)).foregroundColor(.white).cornerRadius(10).disabled(moneyRisked == nil || isTransferring)
                    }
                    if let lotSize = positionSize, let risk = moneyRisked {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Position Size: **\(String(format: "%.2f", lotSize)) lots**").font(subtitleFont)
                                Text("Money Risked: **$\(String(format: "%.2f", risk))**").font(subtitleFont)
                                Divider()
                                Text("This will risk **$\(String(format: "%.2f", risk))** if price hits your stop loss.").font(bodyFont).foregroundStyle(.secondary)
                            }
                        }
                    }
                }.padding(18)
            }.navigationTitle("Forex Calculator")
        }
        .sheet(isPresented: $showAccountBalancePopup) { NumericPopupField(title: "Account Balance ($)", valueText: $accountBalanceText) }
        .sheet(isPresented: $showRiskPercentPopup) { NumericPopupField(title: "Risk %", valueText: $riskPercentText) }
        .sheet(isPresented: $showEntryPricePopup) { NumericPopupField(title: "Entry Price", valueText: $entryPriceText) }
        .sheet(isPresented: $showStopLossPipsPopup) { NumericPopupField(title: "Stop Loss (pips)", valueText: $stopLossPipsText) }
        .sheet(isPresented: $showTakeProfitPipsPopup) { NumericPopupField(title: "Take Profit (pips)", valueText: $takeProfitPipsText) }
    }
    
    func calculatePosition() {
        guard let balance = Double(accountBalanceText), let riskPercent = Double(riskPercentText),
              let stopPips = Double(stopLossPipsText), balance > 0, riskPercent > 0, stopPips > 0 else {
            positionSize = nil; moneyRisked = nil; return
        }
        let risk = balance * (riskPercent / 100.0)
        moneyRisked = risk
        let pipValue = 10.0
        positionSize = risk / (stopPips * pipValue)
    }
    
    func transferToJournal() {
        guard let risk = moneyRisked, risk > 0 else { return }
        isTransferring = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let tp = Double(takeProfitPipsText)
            store.addActive(.init(assetClass: .forex, pairSymbol: selectedPair, risk: risk, openDate: Date(), takeProfitPips: tp))
            NotificationCenter.default.post(name: .switchToJournalTab, object: nil)
            isTransferring = false
        }
    }
}

// MARK: - Journal Views

struct JournalHomeView: View {
    @EnvironmentObject var store: TradeStore
    @State private var showingNewTrade = false
    @State private var selectedDetailTrade: ActiveTrade? = nil
    @State private var showingHistory = false
    @State private var showingSummary = false
    @State private var showingFAQ = false
    @State private var showingPrivacy = false
    @State private var showDrawer = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                VStack(spacing: 0) {
                    HStack {
                        Button { showDrawer.toggle() } label: {
                            Image(systemName: "line.3.horizontal").font(.title2).foregroundColor(.primary)
                        }.padding()
                        Spacer()
                        Text("Active Trades").font(titleFont).foregroundColor(.primary)
                        Spacer()
                        Button { showingNewTrade = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.blue)
                        }.padding()
                    }
                    .background(Color.systemGroupedBackground)
                    Divider()
                    
                    if store.activeTrades.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 60)).foregroundColor(.secondary)
                            Text("No Active Trades").font(.title2).foregroundColor(.secondary)
                            Text("Tap + to add your first trade").font(.subheadline).foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(store.activeTrades) { trade in
                                Button { selectedDetailTrade = trade } label: {
                                    ActiveTradeRow(trade: trade)
                                }
                            }
                            .onDelete { indices in
                                indices.forEach { store.deleteActive(id: store.activeTrades[$0].id) }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                
                if showDrawer {
                    Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { showDrawer = false }
                    DrawerMenu(showHistory: $showingHistory, showSummary: $showingSummary, showFAQ: $showingFAQ,
                              showPrivacy: $showingPrivacy, showDrawer: $showDrawer)
                        .frame(width: 280).background(Color.systemGroupedBackground).transition(.move(edge: .leading))
                }
            }
        }
        .sheet(isPresented: $showingNewTrade) { NewTradeView() }
        .sheet(item: $selectedDetailTrade) { trade in ActiveTradeDetailView(trade: trade) }
        .sheet(isPresented: $showingHistory) { HistoryView() }
        .sheet(isPresented: $showingSummary) { SummaryView() }
        .sheet(isPresented: $showingFAQ) { FAQView() }
        .sheet(isPresented: $showingPrivacy) { PrivacyPolicyView() }
        .animation(.easeInOut, value: showDrawer)
    }
}

struct ActiveTradeRow: View {
    let trade: ActiveTrade
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.pairSymbol).font(subtitleFont).foregroundColor(.primary)
                Text(trade.assetClass.rawValue).font(.caption).foregroundColor(.secondary)
                Text(shortDate(trade.openDate)).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Risk: \(money(trade.risk))").font(bodyFont).foregroundColor(.orange)
                if let tp = trade.takeProfitPips {
                    Text("TP: \(String(format: "%.1f", tp)) pips").font(.caption).foregroundColor(.green)
                }
            }
        }.padding(.vertical, 8)
    }
}

struct DrawerMenu: View {
    @Binding var showHistory: Bool
    @Binding var showSummary: Bool
    @Binding var showFAQ: Bool
    @Binding var showPrivacy: Bool
    @Binding var showDrawer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Menu").font(.title).bold().padding()
            Divider()
            Group {
                DrawerButton(icon: "clock.arrow.circlepath", title: "History") { showHistory = true; showDrawer = false }
                DrawerButton(icon: "chart.bar.fill", title: "Summary") { showSummary = true; showDrawer = false }
                DrawerButton(icon: "questionmark.circle", title: "FAQ") { showFAQ = true; showDrawer = false }
                DrawerButton(icon: "lock.shield", title: "Privacy") { showPrivacy = true; showDrawer = false }
            }
            Spacer()
        }
    }
}

struct DrawerButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).frame(width: 30).foregroundColor(.blue)
                Text(title).font(bodyFont).foregroundColor(.primary)
                Spacer()
            }.padding().background(Color.clear)
        }
    }
}

struct NewTradeView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var assetClass: AssetClass = .forex
    @State private var selectedBase = "EUR"
    @State private var forexPair = "EUR/USD"
    @State private var cryptoPair = "BTC/USD"
    @State private var riskText = ""
    @State private var takeProfitPipsText = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Asset Class", selection: $assetClass) {
                    ForEach(AssetClass.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                
                if assetClass == .forex {
                    Picker("Base", selection: $selectedBase) {
                        ForEach(ForexPairs.baseKeysSorted, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Pair", selection: $forexPair) {
                        ForEach(ForexPairs.groups[selectedBase] ?? [], id: \.self) { Text($0).tag($0) }
                    }
                } else {
                    Picker("Pair", selection: $cryptoPair) {
                        ForEach(CryptoMajors.pairs, id: \.self) { Text($0).tag($0) }
                    }
                }
                
                TextField("Risk Amount ($)", text: $riskText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                TextField("Take Profit (pips) - Optional", text: $takeProfitPipsText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
            .navigationTitle("New Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let risk = Double(riskText), risk > 0 else { return }
                        let pair = assetClass == .forex ? forexPair : cryptoPair
                        let tp = Double(takeProfitPipsText)
                        store.addActive(.init(assetClass: assetClass, pairSymbol: pair, risk: risk, takeProfitPips: tp))
                        dismiss()
                    }.disabled(riskText.isEmpty)
                }
            }
        }
    }
}

struct ActiveTradeDetailView: View {
    let trade: ActiveTrade
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingClose = false

    var body: some View {
        NavigationStack {
            List {
                Section("Trade Details") {
                    HStack { Text("Asset Class"); Spacer(); Text(trade.assetClass.rawValue) }
                    HStack { Text("Pair"); Spacer(); Text(trade.pairSymbol) }
                    HStack { Text("Risk"); Spacer(); Text(money(trade.risk)) }
                    HStack { Text("Open Date"); Spacer(); Text(shortDate(trade.openDate)) }
                    if let tp = trade.takeProfitPips {
                        HStack { Text("Take Profit"); Spacer(); Text("\(String(format: "%.1f", tp)) pips") }
                    }
                }
                Section {
                    Button("Edit Trade") { showingEdit = true }
                    Button("Close Trade") { showingClose = true }
                    Button("Delete Trade", role: .destructive) { store.deleteActive(id: trade.id); dismiss() }
                }
            }
            .navigationTitle("Trade Details")
            .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $showingEdit) { EditActiveTradeSheet(trade: trade) }
        .sheet(isPresented: $showingClose) { CloseTradeSheet(trade: trade) }
    }
}

struct EditActiveTradeSheet: View {
    let trade: ActiveTrade
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var riskText = ""
    @State private var takeProfitPipsText = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Risk Amount ($)", text: $riskText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                TextField("Take Profit (pips)", text: $takeProfitPipsText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
            .navigationTitle("Edit Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let newRisk = Double(riskText), newRisk > 0 else { return }
                        var updated = trade
                        updated.risk = newRisk
                        updated.takeProfitPips = Double(takeProfitPipsText)
                        store.updateActive(updated)
                        dismiss()
                    }
                }
            }
            .onAppear {
                riskText = String(format: "%.2f", trade.risk)
                takeProfitPipsText = trade.takeProfitPips.map { String(format: "%.1f", $0) } ?? ""
            }
        }
    }
}

struct CloseTradeSheet: View {
    let trade: ActiveTrade
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var resultText = ""
    @State private var closeDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Close Date", selection: $closeDate, displayedComponents: .date)
                TextField("Result ($) - use minus for loss", text: $resultText)
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                if let result = Double(resultText) {
                    HStack {
                        Text("Result:")
                        Spacer()
                        Text(money(result)).foregroundColor(result >= 0 ? .green : .red).bold()
                    }
                }
            }
            .navigationTitle("Close Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        guard let result = Double(resultText) else { return }
                        store.close(trade, at: closeDate, result: result)
                        dismiss()
                    }.disabled(resultText.isEmpty)
                }
            }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrade: ClosedTrade? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.closedTrades) { trade in
                    Button { selectedTrade = trade } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trade.pairSymbol).font(subtitleFont)
                                Text(shortDate(trade.closeDate)).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(money(trade.result)).foregroundColor(trade.result >= 0 ? .green : .red).bold()
                        }
                    }
                }
                .onDelete { indices in
                    indices.forEach { store.deleteClosed(id: store.closedTrades[$0].id) }
                }
            }
            .navigationTitle("History")
            .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        }
        .sheet(item: $selectedTrade) { trade in ClosedTradeDetailView(trade: trade) }
    }
}

struct ClosedTradeDetailView: View {
    let trade: ClosedTrade
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Trade Details") {
                    HStack { Text("Pair"); Spacer(); Text(trade.pairSymbol) }
                    HStack { Text("Risk"); Spacer(); Text(money(trade.risk)) }
                    HStack { Text("Result"); Spacer(); Text(money(trade.result)).foregroundColor(trade.result >= 0 ? .green : .red) }
                    HStack { Text("Open Date"); Spacer(); Text(shortDate(trade.openDate)) }
                    HStack { Text("Close Date"); Spacer(); Text(shortDate(trade.closeDate)) }
                }
            }
            .navigationTitle("Closed Trade")
            .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        }
    }
}

struct SummaryView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    var metrics: SummaryMetrics { SummaryMetrics.compute(from: store.closedTrades) }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    HStack { Text("Total Trades"); Spacer(); Text("\(metrics.totalClosed)") }
                    HStack { Text("Win Rate"); Spacer(); Text("\(String(format: "%.1f", metrics.winRate * 100))%") }
                    HStack { Text("Profit Factor"); Spacer(); Text(String(format: "%.2f", metrics.profitFactor)) }
                }
                Section("Performance") {
                    HStack { Text("Gross Profit"); Spacer(); Text(money(metrics.grossProfit)).foregroundColor(.green) }
                    HStack { Text("Gross Loss"); Spacer(); Text(money(-metrics.grossLoss)).foregroundColor(.red) }
                    HStack { Text("Net Profit"); Spacer(); Text(money(metrics.grossProfit - metrics.grossLoss)) }
                }
                Section("Stats") {
                    HStack { Text("Avg Win"); Spacer(); Text(money(metrics.avgWin)) }
                    HStack { Text("Avg Loss"); Spacer(); Text(money(metrics.avgLoss)) }
                    HStack { Text("Largest Win"); Spacer(); Text(money(metrics.largestWin)) }
                    HStack { Text("Largest Loss"); Spacer(); Text(money(metrics.largestLoss)) }
                }
            }
            .navigationTitle("Summary")
            .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        }
    }
}

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Frequently Asked Questions").font(.title).bold().padding(.bottom)
                    FAQItem(q: "How do I add a trade?", a: "Use the calculators to size your position, then tap 'Add to Journal'.")
                    FAQItem(q: "Can I edit trades?", a: "Yes, tap any active trade to edit or close it.")
                    FAQItem(q: "Where is my data stored?", a: "Trades are stored locally and synced via iCloud.")
                }.padding()
            }
            .navigationTitle("FAQ")
            .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        }
    }
}

struct FAQItem: View {
    let q: String
    let a: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(q).font(subtitleFont).bold()
            Text(a).font(bodyFont).foregroundColor(.secondary)
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy").font(.title).bold().padding(.bottom)
                    Text("Your trading data is private and stored securely on your device and iCloud account.")
                    Text("We do not collect, share, or sell your personal information.")
                    Text("For API price fetching, requests are sent to Anthropic's Claude API.")
                }.padding()
            }
            .navigationTitle("Privacy")
            .toolbar { ToolbarItem { Button("Done") { dismiss() } } }
        }
    }
}


// MARK: - Main Home View

struct HomeView: View {
    @EnvironmentObject var store: TradeStore
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TopTabButton(title: "Forex Calc", icon: "chart.bar.doc.horizontal", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TopTabButton(title: "Crypto Calc", icon: "bitcoinsign.circle.fill", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TopTabButton(title: "Journal", icon: "book.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                
                Spacer()
                
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                }
            }
            .background(Color.systemGroupedBackground)
            
            Divider()
            
            Group {
                switch selectedTab {
                case 0:
                    ForexCalculatorTab()
                case 1:
                    CryptoCalculatorTab()
                case 2:
                    JournalHomeView()
                default:
                    ForexCalculatorTab()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToJournalTab)) { _ in
            selectedTab = 2
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct TopTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(bodyFont)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? .blue : .gray)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
    }
}

// MARK: - Numeric Popup Field

struct NumericPopupField: View {
    let title: String
    @Binding var valueText: String
    @Environment(\.dismiss) private var dismiss
    @State private var localValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(title)
                    .font(.title2)
                    .padding(.top)

                TextField("0", text: $localValue)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .focused($isFocused)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                CustomKeypad(value: $localValue)
                    .padding(.horizontal)

                Spacer()
            }

            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        valueText = localValue
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            localValue = valueText
            isFocused = true
        }
    }
}

struct CustomKeypad: View {
    @Binding var value: String
    
    let buttons = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { button in
                        Button {
                            handleButtonTap(button)
                        } label: {
                            Text(button)
                                .font(.system(size: 28, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(button == "⌫" ? Color.red.opacity(0.1) : Color.secondarySystemGroupedBackground)
                                .foregroundColor(button == "⌫" ? .red : .primary)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    if value.hasPrefix("-") {
                        value = String(value.dropFirst())
                    } else {
                        value = "-" + value
                    }
                } label: {
                    Text("+/-")
                        .font(.system(size: 28, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                }
                
                Button {
                    value = ""
                } label: {
                    Text("Clear")
                        .font(.system(size: 28, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    func handleButtonTap(_ button: String) {
        switch button {
        case "⌫":
            if !value.isEmpty {
                value = String(value.dropLast())
            }
        case ".":
            if !value.contains(".") {
                value += button
            }
        default:
            value += button
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            HomeView()
        } else {
            ZStack {
                Color.systemGroupedBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    Text("Trade Journal")
                        .font(.largeTitle)
                        .bold()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

// MARK: - App Entry Point

@main
struct Mac_Trade_JournalkApp: App {
    @StateObject private var store = TradeStore()
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(store)
        }
    }
}

