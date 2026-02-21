//
//  SettingsView.swift
//  Mac_Trade_Journalk
//
//  Settings with API key configuration
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("anthropic_api_key") private var apiKey: String = ""
    @State private var tempApiKey: String = ""
    @State private var showSaveSuccess = false
    @State private var isTesting = false
    @State private var testResult: String? = nil
    @State private var showApiKeyField = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anthropic API Key")
                            .font(.headline)
                        
                        Text("Required for live crypto price fetching")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showApiKeyField {
                                TextField("ant-api03-...", text: $tempApiKey)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .autocapitalization(.none)
                                    #endif
                                    .disableAutocorrection(true)
                                    .font(.system(size: 14, design: .monospaced))
                            } else {
                                Text(apiKeyMasked())
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button {
                                showApiKeyField.toggle()
                                if showApiKeyField && tempApiKey.isEmpty {
                                    tempApiKey = apiKey
                                }
                            } label: {
                                Image(systemName: showApiKeyField ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text("API Configuration")
                }
                
                Section {
                    Button {
                        saveApiKey()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save API Key")
                        }
                    }
                    .disabled(tempApiKey.isEmpty && !showApiKeyField)
                    
                    Button {
                        Task {
                            await testApiKey()
                        }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Testing...")
                            } else {
                                Image(systemName: "network")
                                Text("Test API Key")
                            }
                        }
                    }
                    .disabled(apiKey.isEmpty || isTesting)
                    
                    if let result = testResult {
                        HStack {
                            Image(systemName: result.hasPrefix("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.hasPrefix("✅") ? .green : .red)
                            Text(result)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Actions")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to get an API key:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("1. Go to console.anthropic.com")
                        Text("2. Sign in or create account")
                        Text("3. Click 'API Keys' in sidebar")
                        Text("4. Click 'Create Key'")
                        Text("5. Copy the key (starts with ant-api03-...)")
                        Text("6. Paste it above and tap 'Save'")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } header: {
                    Text("Getting Started")
                }
                
                Section {
                    HStack {
                        Text("Model")
                        Spacer()
                        Text("Claude Sonnet 4")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Endpoint")
                        Spacer()
                        Text("api.anthropic.com")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cost per fetch")
                        Spacer()
                        Text("~$0.003")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("API Info")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("API Key Saved!", isPresented: $showSaveSuccess) {
                Button("OK") { }
            } message: {
                Text("Your API key has been saved successfully.")
            }
        }
        .onAppear {
            tempApiKey = apiKey
        }
    }
    
    private func apiKeyMasked() -> String {
        if apiKey.isEmpty {
            return "Not set"
        } else if apiKey.count > 20 {
            return "\(apiKey.prefix(10))...\(apiKey.suffix(10))"
        } else {
            return String(repeating: "•", count: apiKey.count)
        }
    }
    
    private func saveApiKey() {
        if !tempApiKey.isEmpty {
            apiKey = tempApiKey
            showSaveSuccess = true
            testResult = nil
        }
    }
    
    private func testApiKey() async {
        guard !apiKey.isEmpty else { return }
        
        isTesting = true
        testResult = nil
        
        do {
            let isValid = try await validateApiKey(apiKey)
            await MainActor.run {
                if isValid {
                    testResult = "✅ API key is valid!"
                } else {
                    testResult = "❌ API key is invalid"
                }
                isTesting = false
            }
        } catch {
            await MainActor.run {
                testResult = "❌ Test failed: \(error.localizedDescription)"
                isTesting = false
            }
        }
    }
    
    private func validateApiKey(_ key: String) async throws -> Bool {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10.0
        request.addValue(key, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 10,
            "messages": [
                ["role": "user", "content": "Hi"]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        // 200 = valid, 401 = invalid key
        if httpResponse.statusCode == 200 {
            return true
        } else if httpResponse.statusCode == 401 {
            return false
        } else {
            // Try to parse error
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let type = error["type"] as? String {
                return type != "authentication_error"
            }
            return false
        }
    }
}

#Preview {
    SettingsView()
}

