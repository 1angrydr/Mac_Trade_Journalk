//
//  SettingsView.swift
//  Mac_Trade_Journalk
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: TradeStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("defaultRiskAmount") private var defaultRisk: Double    = 100.0
    @AppStorage("defaultLeverage")   private var defaultLeverage: Double = 50.0
    @AppStorage("defaultAssetClass") private var defaultAsset: String   = "forex"

    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Calculator Defaults
                    settingsCard(title: "Calculator Defaults", icon: "slider.horizontal.3") {
                        labeledRow("Default Risk ($)") {
                            TextField("100", value: $defaultRisk, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                                .multilineTextAlignment(.trailing)
                        }
                        Divider()
                        labeledRow("Default Leverage") {
                            TextField("50", value: $defaultLeverage, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                                .multilineTextAlignment(.trailing)
                        }
                        Divider()
                        labeledRow("Default Asset") {
                            Picker("", selection: $defaultAsset) {
                                Text("Forex").tag("forex")
                                Text("Crypto").tag("crypto")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                    }


                    // MARK: - Data
                    settingsCard(title: "Data", icon: "internaldrive") {
                        Button {
                            showResetConfirm = true
                        } label: {
                            Label("Erase All Trades", systemImage: "trash")
                        }
                        .glassDestructive()
                    }

                    // MARK: - About
                    settingsCard(title: "About", icon: "info.circle") {
                        labeledRow("Version") {
                            Text(appVersion()).foregroundColor(.secondary).font(.appBody)
                        }
                        Divider()
                        labeledRow("Build") {
                            Text(appBuild()).foregroundColor(.secondary).font(.appBody)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Erase all trades?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Erase Everything", role: .destructive) {
                    store.resetAll()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes all active and closed trades. It cannot be undone.")
            }
        }
        .frame(minWidth: 420, minHeight: 500)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            // Card body
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.appSecondaryBackground.opacity(0.5))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
            )
        }
    }

    @ViewBuilder
    private func labeledRow<Content: View>(_ label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(label).font(.appBody)
            Spacer()
            trailing()
        }
    }

    private func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private func appBuild() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

#Preview {
    SettingsView()
        .environmentObject(TradeStore())
}
