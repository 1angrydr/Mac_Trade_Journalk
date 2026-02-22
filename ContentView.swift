//
//  ContentView.swift
//  Mac_Trade_Journalk
//

import SwiftUI
import Combine

// MARK: - App Entry Point

@main
struct Mac_Trade_JournalkApp: App {
    @StateObject private var store = TradeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

// MARK: - Root

struct RootView: View {
    @EnvironmentObject var store: TradeStore
    @State private var selectedTab: Tab = .journal
    @State private var showSettings = false

    enum Tab { case journal, forex, crypto }

    var body: some View {
        VStack(spacing: 0) {
            // Top tab bar
            HStack(spacing: 0) {
                TabButton(label: "Journal",    icon: "book.fill",                 tab: .journal, selected: selectedTab) { selectedTab = .journal }
                TabButton(label: "Forex Calc", icon: "chart.bar.doc.horizontal",  tab: .forex,   selected: selectedTab) { selectedTab = .forex }
                TabButton(label: "Crypto Calc",icon: "bitcoinsign.circle.fill",   tab: .crypto,  selected: selectedTab) { selectedTab = .crypto }
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(
                            ZStack {
                                Circle().fill(.ultraThinMaterial)
                                Circle().fill(Color.blue.opacity(0.10))
                                Circle().strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .frame(height: 56)
            .background(Color.appBackground)

            Divider()

            // Content
            switch selectedTab {
            case .journal: JournalView()
            case .forex:   ForexCalculatorView()
            case .crypto:  CryptoCalculatorView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToJournalTab)) { _ in
            selectedTab = .journal
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
    }
}

struct TabButton: View {
    let label: String
    let icon: String
    let tab: RootView.Tab
    let selected: RootView.Tab
    let action: () -> Void

    var isSelected: Bool { tab == selected }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .frame(maxWidth: 140)
            .frame(height: 56)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.12))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - ============================================================
// MARK: - JOURNAL
// MARK: - ============================================================

struct JournalView: View {
    @EnvironmentObject var store: TradeStore
    @State private var showAddForex   = false
    @State private var showAddCrypto  = false
    @State private var showHistory    = false
    @State private var showSummary    = false
    @State private var showFAQ        = false
    @State private var showPrivacy    = false
    @State private var selectedTrade: ActiveTrade? = nil

    private var sorted: [ActiveTrade] {
        store.activeTrades.sorted { $0.openDate > $1.openDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Mac Trade Journal").font(.appTitle)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Add buttons
            HStack(spacing: 12) {
                Button { showAddForex = true } label: {
                    Label("Add Forex", systemImage: "plus.circle.fill")
                }
                .glassFill(tint: .blue)

                Button { showAddCrypto = true } label: {
                    Label("Add Crypto", systemImage: "plus.circle.fill")
                }
                .glassFill(tint: .orange)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            Divider()

            // Trade list
            if sorted.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "tray").font(.system(size: 44)).foregroundColor(.secondary)
                    Text("No active trades").font(.title3).foregroundColor(.secondary)
                    Text("Click Add Forex or Add Crypto above").font(.appBody).foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sorted) { trade in
                            Button { selectedTrade = trade } label: {
                                ActiveTradeCard(trade: trade)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                    .padding(16)
                }
            }

            Divider()

            // Bottom nav tray
            HStack(spacing: 0) {
                NavTrayButton(icon: "clock.arrow.circlepath", label: "History")  { showHistory = true }
                NavTrayButton(icon: "chart.pie",              label: "Summary")  { showSummary = true }
                NavTrayButton(icon: "questionmark.circle",    label: "FAQ")      { showFAQ     = true }
                NavTrayButton(icon: "lock.shield",            label: "Privacy")  { showPrivacy = true }
            }
            .frame(height: 52)
            .background(Color.appSecondaryBackground)
        }
        .sheet(isPresented: $showAddForex)  { AddTradeView(assetClass: .forex).environmentObject(store) }
        .sheet(isPresented: $showAddCrypto) { AddTradeView(assetClass: .crypto).environmentObject(store) }
        .sheet(item: $selectedTrade)        { t in TradeDetailView(trade: t).environmentObject(store) }
        .sheet(isPresented: $showHistory)   { HistoryView().environmentObject(store) }
        .sheet(isPresented: $showSummary)   { SummaryView().environmentObject(store) }
        .sheet(isPresented: $showFAQ)       { FAQView() }
        .sheet(isPresented: $showPrivacy)   { PrivacyView() }
    }
}

struct NavTrayButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 18))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.ultraThinMaterial)
                    Color.blue.opacity(0.04)
                }
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

struct ActiveTradeCard: View {
    let trade: ActiveTrade
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(trade.pairSymbol).font(.headline)
                Text("\(trade.assetClass.rawValue) · Opened \(shortDate(trade.openDate))")
                    .font(.appCaption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(money(trade.risk)).font(.appSubtitle).bold().foregroundColor(.blue)
                if let tp = trade.takeProfitPips {
                    Text("TP \(String(format: "%.1f", tp)) pips").font(.appCaption).foregroundColor(.green)
                }
            }
            Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
        }
        .padding(12)
        .background(Color.appSecondaryBackground)
        .cornerRadius(10)
    }
}

// MARK: - Add Trade

struct AddTradeView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    let assetClass: AssetClass

    @State private var openDate          = Date()
    @State private var selectedBase      = "EUR"
    @State private var selectedForexPair = "EUR/USD"
    @State private var selectedCryptoPair = "BTC/USD"
    @State private var riskText          = ""
    @State private var takeProfitText    = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Open Date") {
                    DatePicker("Date", selection: $openDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                Section(assetClass == .forex ? "Forex Pair" : "Crypto Pair") {
                    if assetClass == .forex {
                        Picker("Base", selection: $selectedBase) {
                            ForEach(ForexPairs.baseKeysSorted, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedBase) { _, new in
                            selectedForexPair = ForexPairs.groups[new]?.sorted().first ?? ""
                        }
                        Picker("Pair", selection: $selectedForexPair) {
                            ForEach((ForexPairs.groups[selectedBase] ?? []).sorted(), id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Picker("Pair", selection: $selectedCryptoPair) {
                            ForEach(CryptoMajors.pairs, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Risk (USD)") {
                    HStack {
                        Text("$").foregroundColor(.secondary)
                        TextField("0.00", text: $riskText)
                    }
                }

                Section("Take Profit — Optional") {
                    TextField("pips e.g. 50", text: $takeProfitText)
                }

                Section {
                    Button {
                        guard let risk = Double(riskText), risk > 0 else { return }
                        let pair = assetClass == .forex ? selectedForexPair : selectedCryptoPair
                        store.addActive(ActiveTrade(
                            assetClass: assetClass,
                            pairSymbol: pair,
                            risk: risk,
                            openDate: openDate,
                            takeProfitPips: Double(takeProfitText)
                        ))
                        dismiss()
                    } label: {
                        Label("Add Trade", systemImage: "plus.circle.fill")
                    }
                    .primaryBlue()
                    .disabled((Double(riskText) ?? 0) <= 0)
                }
            }
            .navigationTitle(assetClass == .forex ? "New Forex Trade" : "New Crypto Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                if assetClass == .forex {
                    selectedForexPair = ForexPairs.groups[selectedBase]?.sorted().first ?? ""
                }
            }
        }
    }
}

// MARK: - Trade Detail

struct TradeDetailView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    let trade: ActiveTrade
    @State private var showEdit  = false
    @State private var showClose = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Trade Info") {
                    row("Asset",    trade.assetClass.rawValue)
                    row("Pair",     trade.pairSymbol)
                    row("Risk",     money(trade.risk))
                    row("Opened",   shortDate(trade.openDate))
                    if let tp = trade.takeProfitPips {
                        row("Take Profit", "\(String(format: "%.1f", tp)) pips")
                    }
                }
                Section("Actions") {
                    Button { showEdit = true } label: {
                        Label("Edit Trade", systemImage: "pencil").frame(maxWidth: .infinity)
                    }
                    .glassButton(tint: .blue)

                    Button { showClose = true } label: {
                        Label("Close Trade", systemImage: "xmark.circle.fill").frame(maxWidth: .infinity)
                    }
                    .glassFill(tint: .blue)

                    Button { confirmDelete = true } label: {
                        Label("Delete Trade", systemImage: "trash").frame(maxWidth: .infinity)
                    }
                    .glassDestructive()
                }
            }
            .navigationTitle(trade.pairSymbol)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showEdit)  { EditActiveView(trade: trade).environmentObject(store) }
            .sheet(isPresented: $showClose) { CloseTradeView(trade: trade).environmentObject(store) }
            .alert("Delete this trade?", isPresented: $confirmDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { store.deleteActive(id: trade.id); dismiss() }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundColor(.secondary) }
    }
}

// MARK: - Edit Active Trade

struct EditActiveView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    let trade: ActiveTrade
    @State private var openDate:       Date
    @State private var riskText:       String
    @State private var takeProfitText: String

    init(trade: ActiveTrade) {
        self.trade = trade
        _openDate       = State(initialValue: trade.openDate)
        _riskText       = State(initialValue: String(format: "%.2f", trade.risk))
        _takeProfitText = State(initialValue: trade.takeProfitPips.map { String(format: "%.1f", $0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Open Date") {
                    DatePicker("Date", selection: $openDate, displayedComponents: .date)
                }
                Section("Risk (USD)") {
                    HStack {
                        Text("$").foregroundColor(.secondary)
                        TextField("0.00", text: $riskText)
                    }
                }
                Section("Take Profit — Optional") {
                    TextField("pips e.g. 50", text: $takeProfitText)
                }
                Section {
                    Button {
                        guard let risk = Double(riskText), risk > 0 else { return }
                        var updated          = trade
                        updated.openDate     = openDate
                        updated.risk         = risk
                        updated.takeProfitPips = Double(takeProfitText)
                        store.updateActive(updated)
                        dismiss()
                    } label: {
                        Label("Save Changes", systemImage: "checkmark.circle.fill")
                    }
                    .primaryBlue()
                    .disabled((Double(riskText) ?? 0) <= 0)
                }
            }
            .navigationTitle("Edit Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

// MARK: - Close Trade

struct CloseTradeView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    let trade: ActiveTrade
    @State private var closeDate  = Date()
    @State private var resultText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Close Date") {
                    DatePicker("Date", selection: $closeDate, displayedComponents: .date)
                }
                Section("Result (+ profit / − loss)") {
                    HStack {
                        Text("$").foregroundColor(.secondary)
                        TextField("+/− 0.00", text: $resultText)
                    }
                    if let r = Double(resultText) {
                        HStack {
                            Text("Preview:")
                            Spacer()
                            Text(money(r)).foregroundColor(r >= 0 ? .green : .red).bold()
                        }
                    }
                }
                Section {
                    Button {
                        guard let r = Double(resultText) else { return }
                        store.close(trade, at: closeDate, result: r)
                        dismiss()
                    } label: {
                        Label("Confirm Close", systemImage: "checkmark.circle.fill")
                    }
                    .primaryBlue()
                    .disabled(Double(resultText) == nil)
                }
            }
            .navigationTitle("Close Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - HISTORY
// MARK: - ============================================================

struct HistoryView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var editingActive: ActiveTrade? = nil
    @State private var editingClosed: ClosedTrade? = nil

    private var activesSorted: [ActiveTrade] {
        store.activeTrades.sorted { $0.openDate > $1.openDate }
    }
    private var closedSorted: [ClosedTrade] {
        store.closedTrades.sorted { $0.closeDate > $1.closeDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ---- Active Trades ----
                    SectionHeader(title: "Active Trades (\(activesSorted.count))")

                    if activesSorted.isEmpty {
                        EmptyRowLabel(text: "No active trades")
                    } else {
                        ForEach(activesSorted) { trade in
                            HistoryActiveRow(trade: trade) { editingActive = trade }
                        }
                    }

                    Divider().padding(.vertical, 14)

                    // ---- Closed Trades ----
                    SectionHeader(title: "Closed Trades (\(closedSorted.count))")

                    if closedSorted.isEmpty {
                        EmptyRowLabel(text: "No closed trades")
                    } else {
                        ForEach(closedSorted) { trade in
                            HistoryClosedRow(trade: trade) { editingClosed = trade }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.appBackground)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(item: $editingActive) { t in
                EditActiveView(trade: t).environmentObject(store)
            }
            .sheet(item: $editingClosed) { t in
                EditClosedView(trade: t).environmentObject(store)
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title3).bold()
            .padding(.bottom, 8)
    }
}

private struct EmptyRowLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.appBody).foregroundColor(.secondary)
            .padding(.bottom, 8)
    }
}

private struct HistoryActiveRow: View {
    let trade: ActiveTrade
    let onEdit: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(trade.pairSymbol).font(.headline)
                Text("\(trade.assetClass.rawValue) · Opened \(shortDate(trade.openDate))")
                    .font(.appCaption).foregroundColor(.secondary)
            }
            Spacer()
            Text(money(trade.risk)).font(.appSubtitle).bold().foregroundColor(.blue)
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2).foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .frame(width: 36, height: 36)
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.appSecondaryBackground.opacity(0.6))
            }
        )
        .cornerRadius(10)
        .padding(.bottom, 6)
    }
}

private struct HistoryClosedRow: View {
    let trade: ClosedTrade
    let onEdit: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(trade.pairSymbol).font(.headline)
                Text("\(trade.assetClass.rawValue) · Closed \(shortDate(trade.closeDate))")
                    .font(.appCaption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(money(trade.result))
                    .font(.appSubtitle).bold()
                    .foregroundColor(trade.result >= 0 ? .green : .red)
                Text("Risk \(money(trade.risk))").font(.appCaption).foregroundColor(.secondary)
            }
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2).foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .frame(width: 36, height: 36)
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.appSecondaryBackground.opacity(0.6))
            }
        )
        .cornerRadius(10)
        .padding(.bottom, 6)
    }
}

// MARK: - Edit Closed Trade

struct EditClosedView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    let trade: ClosedTrade
    @State private var closeDate:  Date
    @State private var resultText: String
    @State private var confirmDelete = false

    init(trade: ClosedTrade) {
        self.trade = trade
        _closeDate  = State(initialValue: trade.closeDate)
        _resultText = State(initialValue: String(format: "%.2f", trade.result))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trade Info") {
                    HStack { Text("Pair"); Spacer(); Text(trade.pairSymbol).foregroundColor(.secondary) }
                    HStack { Text("Risk"); Spacer(); Text(money(trade.risk)).foregroundColor(.secondary) }
                    HStack { Text("Opened"); Spacer(); Text(shortDate(trade.openDate)).foregroundColor(.secondary) }
                }
                Section("Close Date") {
                    DatePicker("Date", selection: $closeDate, displayedComponents: .date)
                }
                Section("Result (+ profit / − loss)") {
                    HStack {
                        Text("$").foregroundColor(.secondary)
                        TextField("+/− 0.00", text: $resultText)
                    }
                    if let r = Double(resultText) {
                        HStack {
                            Text("Preview:")
                            Spacer()
                            Text(money(r)).foregroundColor(r >= 0 ? .green : .red).bold()
                        }
                    }
                }
                Section {
                    Button {
                        guard let r = Double(resultText) else { return }
                        var updated = trade
                        updated.result    = r
                        updated.closeDate = closeDate
                        store.updateClosed(updated)
                        dismiss()
                    } label: {
                        Label("Save Changes", systemImage: "checkmark.circle.fill")
                    }
                    .primaryBlue()
                    .disabled(Double(resultText) == nil)

                    Button { confirmDelete = true } label: {
                        Label("Delete Trade", systemImage: "trash")
                    }
                    .glassDestructive()
                }
            }
            .navigationTitle("Edit Closed Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .alert("Delete this trade?", isPresented: $confirmDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { store.deleteClosed(id: trade.id); dismiss() }
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - SUMMARY
// MARK: - ============================================================

struct SummaryView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmErase = false

    private var m: SummaryMetrics { SummaryMetrics.compute(from: store.closedTrades) }

    private var rows: [(String, String)] {[
        ("Closed Trades",  "\(m.totalClosed)"),
        ("Winning Trades", "\(m.winTrades)"),
        ("Losing Trades",  "\(m.lossTrades)"),
        ("Win Rate",       String(format: "%.1f%%", m.winRate * 100)),
        ("Avg Win",        money(m.avgWin)),
        ("Avg Loss",       money(abs(m.avgLoss))),
        ("Largest Win",    money(m.largestWin)),
        ("Largest Loss",   money(abs(m.largestLoss))),
        ("Gross Profit",   money(m.grossProfit)),
        ("Gross Loss",     money(m.grossLoss)),
        ("Profit Factor",  m.profitFactor.isInfinite ? "∞" : String(format: "%.2f", m.profitFactor))
    ]}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(rows, id: \.0) { label, value in
                        HStack {
                            Text(label).font(.appBody).foregroundColor(.secondary)
                            Spacer()
                            Text(value).font(.appSubtitle).bold()
                        }
                        .padding(12)
                        .background(Color.appSecondaryBackground)
                        .cornerRadius(9)
                    }

                    Button { confirmErase = true } label: {
                        Text("Erase All Trades")
                    }
                    .glassDestructive()
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Erase all trades?", isPresented: $confirmErase) {
                Button("Cancel", role: .cancel) {}
                Button("Erase", role: .destructive) { store.resetAll() }
            } message: {
                Text("This permanently deletes every active and closed trade.")
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - FAQ
// MARK: - ============================================================

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, String)] = [
        ("How do I add a trade?",
         "Go to the Journal tab. Click 'Add Forex' or 'Add Crypto'. Set the open date, choose your pair, enter your risk amount in dollars, then click Add Trade."),

        ("How do I close a trade?",
         "On the Journal tab, click any active trade card to open its detail. Click 'Close Trade', pick a close date, enter the result (positive = profit, negative = loss), then click Confirm Close."),

        ("How do I edit an active trade?",
         "Click the trade card on the Journal tab to open its detail, then click 'Edit Trade'. You can change the open date, risk, and take profit target."),

        ("How do I edit or delete a closed trade?",
         "Open History from the bottom nav tray. Every row has an orange pencil button. Click it to open an edit sheet where you can change the result, close date, or delete the trade."),

        ("How do I use the Forex Calculator?",
         "Click the Forex Calc tab. Choose your currency pair with the segmented picker, enter your entry price, stop loss price, and risk amount. Click 'Calculate Units' to see position size in micro lots, pip value, notional, and margin required at 50:1 leverage."),

        ("How do I use the Crypto Calculator?",
         "Click the Crypto Calc tab. Choose your pair, enter entry price, stop loss price, risk amount, and leverage. Click 'Calculate Units' to see position size, stop distance, notional value, and margin required."),

        ("Where is my data stored?",
         "Trades are saved locally on your Mac via UserDefaults and synced to your private iCloud account via CloudKit. No data is ever sent to third-party servers."),

        ("How do I change default risk or leverage?",
         "Open Settings (gear icon, top right) and adjust the Calculator Defaults. These pre-fill the risk and leverage fields each time you open a calculator.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(items, id: \.0) { q, a in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(q).font(.appSubtitle).foregroundColor(.primary)
                            Text(a).font(.appBody).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appSecondaryBackground)
                        .cornerRadius(10)
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("FAQ")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - PRIVACY
// MARK: - ============================================================

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Group {
                        Text("Privacy Policy").font(.appTitle)
                        Text("Mac Trade Journal respects your privacy.").font(.appSubtitle)
                        Text("All trade data is stored locally on your Mac and synced to your personal iCloud account. No data is collected, transmitted, or shared with any third party.")
                        Text("Data Stored Locally").font(.appSubtitle)
                        Text("• Trade pairs, dates, risk amounts, and results\n• Calculator inputs (not persisted)\n• Settings preferences (stored in UserDefaults)")
                        Text("iCloud Sync").font(.appSubtitle)
                        Text("Trades sync across your own Mac devices via CloudKit in your private iCloud database. Only you can access this data.")
                        Text("Deleting the App").font(.appSubtitle)
                        Text("Deleting the app removes all local data. iCloud data can be managed in System Settings → Apple ID → iCloud.")
                    }
                    .font(.appBody)
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - FOREX CALCULATOR
// MARK: - ============================================================

struct ForexCalculatorView: View {
    private let pairGroups: [String: [String]] = [
        "AUD": ["AUD/CAD","AUD/CHF","AUD/JPY","AUD/NZD","AUD/USD"],
        "CAD": ["CAD/CHF","CAD/JPY"],
        "CHF": ["CHF/JPY"],
        "EUR": ["EUR/AUD","EUR/CAD","EUR/CHF","EUR/GBP","EUR/JPY","EUR/NZD","EUR/USD"],
        "GBP": ["GBP/AUD","GBP/CAD","GBP/CHF","GBP/JPY","GBP/NZD","GBP/USD"],
        "NZD": ["NZD/CAD","NZD/CHF","NZD/JPY","NZD/USD"],
        "USD": ["USD/CAD","USD/CHF","USD/JPY"]
    ]
    private let defaultRates: [String: Double] = [
        "USD/JPY": 150.00, "EUR/USD": 1.0850, "GBP/USD": 1.2700,
        "AUD/USD": 0.6600, "NZD/USD": 0.6100, "USD/CAD": 1.3600,
        "USD/CHF": 0.8800
    ]
    private let leverage = 50.0

    @State private var selectedBase  = "EUR"
    @State private var selectedPair  = "EUR/USD"
    @State private var entryText     = ""
    @State private var stopText      = ""
    @State private var riskText      = ""
    @State private var convText      = ""

    // Results
    @State private var result: ForexResult? = nil

    struct ForexResult {
        let pips: Double
        let units: Double
        let pipValue: Double
        let notional: Double
        let margin: Double
    }

    private enum PairType { case quoteUSD, baseUSD, cross }

    private var pairType: PairType {
        let q = quoteCurrency
        if q == "USD" { return .quoteUSD }
        if baseCurrency == "USD" { return .baseUSD }
        return .cross
    }
    private var baseCurrency: String { String(selectedPair.prefix(3)) }
    private var quoteCurrency: String { String(selectedPair.suffix(3)) }

    private var convPairNeeded: String? {
        switch pairType {
        case .quoteUSD: return nil
        case .baseUSD:  return selectedPair
        case .cross:
            switch quoteCurrency {
            case "JPY": return "USD/JPY"
            case "CHF": return "USD/CHF"
            case "CAD": return "USD/CAD"
            case "GBP": return "GBP/USD"
            case "AUD": return "AUD/USD"
            case "NZD": return "NZD/USD"
            case "EUR": return "EUR/USD"
            default: return nil
            }
        }
    }
    private var defaultConvRate: Double { defaultRates[convPairNeeded ?? ""] ?? 1.0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("💱 Forex Position Calculator").font(.appTitle)

                    GroupBox("Instrument") {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Base", selection: $selectedBase) {
                                ForEach(pairGroups.keys.sorted(), id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedBase) { _, new in
                                selectedPair = pairGroups[new]?.sorted().first ?? ""
                                convText = ""
                                result = nil
                            }
                            Picker("Pair", selection: $selectedPair) {
                                ForEach((pairGroups[selectedBase] ?? []).sorted(), id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedPair) { _, _ in convText = ""; result = nil }
                        }
                    }

                    GroupBox("Position Parameters") {
                        VStack(alignment: .leading, spacing: 10) {
                            fieldRow("Entry Price",      "e.g. 1.0850",  $entryText)
                            fieldRow("Stop Loss Price",  "e.g. 1.0800",  $stopText)
                            fieldRow("Risk Amount ($)",  "e.g. 25",      $riskText)
                            if let cp = convPairNeeded {
                                fieldRow("\(cp) Rate", String(format: "%.4f", defaultConvRate), $convText)
                                Text("Conversion rate for pip-to-USD calculation (default pre-filled)")
                                    .font(.appCaption).foregroundColor(.secondary)
                            }
                            HStack { Text("Leverage"); Spacer(); Text("50:1 (Fixed)").foregroundColor(.secondary) }
                        }
                    }

                    Button(action: calculate) {
                        Text("Calculate Units")
                    }
                    .glassFill(tint: .blue)

                    if let r = result {
                        GroupBox("Result") {
                            VStack(alignment: .leading, spacing: 8) {
                                resultRow("Position Size", "\(String(format: "%.2f", r.units / 1000)) micro lots")
                                resultRow("", "(\(String(format: "%.5f", r.units / 100_000)) std = \(Int(r.units)) units)")
                                resultRow("Stop Distance",  "\(String(format: "%.1f", r.pips)) pips")
                                resultRow("Pip Value",      money(r.pipValue))
                                resultRow("Notional",       money(r.notional))
                                resultRow("Margin (50:1)",  money(r.margin))
                                Text("Risk \(money(Double(riskText) ?? 0)) if stop hit at \(stopText).")
                                    .font(.appCaption).foregroundColor(.secondary).padding(.top, 2)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .navigationTitle("Forex Calculator")
        }
        .onAppear {
            selectedPair = pairGroups[selectedBase]?.sorted().first ?? ""
        }
    }

    private func fieldRow(_ label: String, _ placeholder: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 140, alignment: .leading)
            TextField(placeholder, text: binding).textFieldStyle(.roundedBorder)
        }
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.appBody).foregroundColor(label.isEmpty ? .clear : .secondary)
            Spacer()
            Text(value).font(.appBody).bold()
        }
    }

    private func calculate() {
        guard let entry = Double(entryText),
              let stop  = Double(stopText),
              let risk  = Double(riskText),
              entry > 0, stop > 0, risk > 0 else { result = nil; return }

        let q       = quoteCurrency
        let pipSize = q == "JPY" ? 0.01 : 0.0001
        let pips    = abs(entry - stop) / pipSize
        guard pips > 0 else { result = nil; return }

        let convRate = Double(convText) ?? defaultConvRate
        let pipPerUnit: Double
        switch pairType {
        case .quoteUSD: pipPerUnit = pipSize
        case .baseUSD:  pipPerUnit = pipSize / entry
        case .cross:
            if q == "JPY" || q == "CHF" || q == "CAD" {
                pipPerUnit = pipSize / convRate
            } else {
                pipPerUnit = pipSize * convRate
            }
        }

        let riskPerUnit = pips * pipPerUnit
        guard riskPerUnit > 0 else { result = nil; return }

        let units   = risk / riskPerUnit
        let notional = units * entry
        result = ForexResult(
            pips: pips, units: units,
            pipValue: pipPerUnit * units,
            notional: notional,
            margin: notional / leverage
        )
    }
}

// MARK: - ============================================================
// MARK: - CRYPTO CALCULATOR
// MARK: - ============================================================

struct CryptoCalculatorView: View {
    @State private var selectedPair = "BTC/USD"
    @State private var entryText    = ""
    @State private var stopText     = ""
    @State private var riskText     = ""
    @State private var levText      = "1"

    struct CryptoResult {
        let distance: Double
        let units: Double
        let notional: Double
        let margin: Double
    }
    @State private var result: CryptoResult? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("₿ Crypto Unit Calculator").font(.appTitle)

                    GroupBox("Instrument") {
                        Picker("Pair", selection: $selectedPair) {
                            ForEach(CryptoMajors.pairs, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }

                    GroupBox("Position Parameters") {
                        VStack(alignment: .leading, spacing: 10) {
                            fieldRow("Entry Price",     "e.g. 95000",  $entryText)
                            fieldRow("Stop Loss Price", "e.g. 93000",  $stopText)
                            fieldRow("Risk Amount ($)", "e.g. 100",    $riskText)
                            fieldRow("Leverage (×)",    "e.g. 5",      $levText)
                        }
                        Text("Leverage only reduces required margin — your risk amount stays fixed.")
                            .font(.appCaption).foregroundColor(.secondary).padding(.top, 4)
                    }

                    Button(action: calculate) {
                        Text("Calculate Units")
                    }
                    .glassFill(tint: .orange)

                    if let r = result {
                        GroupBox("Result") {
                            VStack(alignment: .leading, spacing: 8) {
                                resultRow("Position Size",  String(format: "%.6f units", r.units))
                                resultRow("Stop Distance",  money(r.distance) + " per unit")
                                resultRow("Notional",       money(r.notional))
                                resultRow("Margin",         money(r.margin))
                                Text("Risk \(money(Double(riskText) ?? 0)) if stop hit at \(stopText).")
                                    .font(.appCaption).foregroundColor(.secondary).padding(.top, 2)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .navigationTitle("Crypto Calculator")
        }
    }

    private func fieldRow(_ label: String, _ placeholder: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 140, alignment: .leading)
            TextField(placeholder, text: binding).textFieldStyle(.roundedBorder)
        }
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.appBody).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.appBody).bold()
        }
    }

    private func calculate() {
        guard let entry = Double(entryText),
              let stop  = Double(stopText),
              let risk  = Double(riskText),
              let lev   = Double(levText),
              entry > 0, stop > 0, risk > 0, lev > 0 else { result = nil; return }

        let dist = abs(entry - stop)
        guard dist > 0 else { result = nil; return }

        let units    = risk / dist
        let notional = units * entry
        result = CryptoResult(distance: dist, units: units, notional: notional, margin: notional / lev)
    }
}
