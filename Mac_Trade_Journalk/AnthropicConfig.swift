//
//  AnthropicConfig.swift
//  Mac_Trade_Journalk
//

import Foundation

struct AnthropicConfig {
    // Read from Settings (UserDefaults)
    static var apiKey: String {
        UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    }
    
    static let endpoint = "https://api.anthropic.com/v1/messages"
    static let model = "claude-sonnet-4-5-20250929"
}
