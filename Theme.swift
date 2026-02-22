//
//  Theme.swift
//  Mac_Trade_Journalk
//

import SwiftUI
import AppKit

// MARK: - Colors

extension Color {
    static let appBackground          = Color(NSColor.windowBackgroundColor)
    static let appSecondaryBackground = Color(NSColor.controlBackgroundColor)
}

// MARK: - Fonts

extension Font {
    static let appTitle    = Font.system(size: 18, weight: .bold)
    static let appSubtitle = Font.system(size: 15, weight: .semibold)
    static let appBody     = Font.system(size: 14)
    static let appCaption  = Font.system(size: 12)
    static let appTable    = Font.system(size: 13)
}

// MARK: - Helpers

let tableFont       = Font.appTable
let tableHeaderFont = Font.system(size: 13, weight: .semibold)
let compactInsets   = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

// MARK: - Liquid Glass Button Style
// Translucent frosted background with a subtle border — visible on any bg

struct GlassButtonStyle: ButtonStyle {
    var tintColor: Color = .blue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(tintColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    // Frosted base
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // Tint overlay
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tintColor.opacity(configuration.isPressed ? 0.25 : 0.12))
                    // Border
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(tintColor.opacity(0.5), lineWidth: 1)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

// Full-width solid fill variant (for primary actions like "Add Trade")
struct GlassFillButtonStyle: ButtonStyle {
    var tintColor: Color = .blue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tintColor.opacity(configuration.isPressed ? 0.7 : 1.0))
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.25))
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

// Destructive red variant
struct GlassDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.red.opacity(configuration.isPressed ? 0.25 : 0.10))
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

// Legacy alias kept for any call sites that use .primaryBlue()
struct PrimaryBlueButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        GlassFillButtonStyle(tintColor: .blue).makeBody(configuration: configuration)
    }
}

extension View {
    func primaryBlue() -> some View { buttonStyle(PrimaryBlueButton()) }
    func glassButton(tint: Color = .blue) -> some View { buttonStyle(GlassButtonStyle(tintColor: tint)) }
    func glassFill(tint: Color = .blue) -> some View { buttonStyle(GlassFillButtonStyle(tintColor: tint)) }
    func glassDestructive() -> some View { buttonStyle(GlassDestructiveButtonStyle()) }
}

// MARK: - Table Cell Modifier

struct TableCellModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appTable)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .allowsTightening(true)
    }
}

extension View {
    func tableCell() -> some View { modifier(TableCellModifier()) }
}

// MARK: - Formatters

func money(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "USD"
    return f.string(from: NSNumber(value: v)) ?? String(format: "$%.2f", v)
}

func shortDate(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .none
    return f.string(from: d)
}
