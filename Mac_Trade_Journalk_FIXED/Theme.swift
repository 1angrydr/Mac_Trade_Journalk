//
//  Theme.swift
//  Mac_Trade_Journalk
//
//  UI Theme, fonts, colors, and styling
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Platform Colors

extension Color {
    static var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    static var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}

// MARK: - Fonts

let titleFont = Font.system(size: 18, weight: .bold)
let subtitleFont = Font.system(size: 16, weight: .semibold)
let bodyFont = Font.system(size: 14)
let tableFont = Font.system(size: 14)
let tableHeaderFont = Font.system(size: 14, weight: .semibold)
let compactInsets = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

// MARK: - Page Skin

enum PageSkin {
    case white, green, gray
    
    var bg: Color {
        switch self {
        case .white: return .white
        case .green: return Color(red: 0.06, green: 0.55, blue: 0.26)
        case .gray:  return Color(white: 0.15)
        }
    }
    
    var text: Color {
        self == .white ? .black : .white
    }
    
    var subtle: Color {
        self == .white ? .secondary : .white.opacity(0.8)
    }
}

// MARK: - Button Styles

struct PrimaryBlueButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

extension Button {
    func primaryBlue() -> some View {
        buttonStyle(PrimaryBlueButton())
    }
}

// MARK: - View Modifiers

struct TableCell: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .allowsTightening(true)
            .foregroundColor(.black)
            .font(tableFont)
    }
}

extension View {
    func tableCell() -> some View {
        modifier(TableCell())
    }
}

// MARK: - Formatters

func money(_ v: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .currency
    nf.currencyCode = "USD"
    return nf.string(from: NSNumber(value: v)) ?? String(format: "$%.2f", v)
}

func shortDate(_ d: Date) -> String {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .none
    return df.string(from: d)
}
