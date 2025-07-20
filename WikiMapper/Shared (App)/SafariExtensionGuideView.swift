//
//  SafariExtensionGuideView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

#if os(macOS)
import SafariServices
#endif

/// Guide view for helping users enable Safari extension
struct SafariExtensionGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExtensionEnabled = false
    @State private var isCheckingExtension = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Status indicator
                    statusSection
                    
                    // Instructions
                    instructionsSection
                    
                    // Action buttons
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Safari Extension Setup")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .toolbar {
                ToolbarItem(placement: toolbarPlacement) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkExtensionStatus()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "safari")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Enable WikiMapper Extension")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("To track your Wikipedia browsing history, you need to enable the WikiMapper extension in Safari")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        HStack(spacing: 12) {
            Image(systemName: isExtensionEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(isExtensionEnabled ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Extension Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(isExtensionEnabled ? "Enabled" : "Disabled")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isExtensionEnabled ? .green : .orange)
            }
            
            Spacer()
            
            Button("Recheck") {
                checkExtensionStatus()
            }
            .disabled(isCheckingExtension)
        }
        .padding()
        .background(backgroundColorForPlatform)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup Steps")
                .font(.headline)
                .fontWeight(.bold)
            
#if os(iOS)
            instructionStepsIOS
#elseif os(macOS)
            instructionStepsMaxOS
#endif
        }
    }
    
#if os(iOS)
    private var instructionStepsIOS: some View {
        VStack(alignment: .leading, spacing: 12) {
            InstructionStep(
                number: 1,
                title: "Open Safari Settings",
                description: "In Safari browser, tap the share button in the bottom right, then select \"Settings\""
            )
            
            InstructionStep(
                number: 2,
                title: "Find Extensions Option",
                description: "In the settings page, scroll down to find the \"Extensions\" option"
            )
            
            InstructionStep(
                number: 3,
                title: "Enable WikiMapper",
                description: "Find WikiMapper in the extensions list and turn on its toggle"
            )
            
            InstructionStep(
                number: 4,
                title: "Grant Permissions",
                description: "Make sure to grant WikiMapper access to Wikipedia websites"
            )
        }
    }
#elseif os(macOS)
    private var instructionStepsMaxOS: some View {
        VStack(alignment: .leading, spacing: 12) {
            InstructionStep(
                number: 1,
                title: "Open Safari Preferences",
                description: "In Safari menu, select \"Preferences\" or press Cmd+,"
            )
            
            InstructionStep(
                number: 2,
                title: "Select Extensions Tab",
                description: "Click the \"Extensions\" tab at the top of the preferences window"
            )
            
            InstructionStep(
                number: 3,
                title: "Enable WikiMapper",
                description: "Find WikiMapper in the left extensions list and check the enable checkbox"
            )
            
            InstructionStep(
                number: 4,
                title: "Configure Permissions",
                description: "Make sure to grant the extension access to all websites or specific Wikipedia sites"
            )
        }
    }
#endif
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: 12) {
#if os(macOS)
            Button("Open Safari Extension Preferences") {
                openSafariExtensionPreferences()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
#endif
            
            Button("Finish Setup") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColorForPlatform: Color {
#if os(iOS)
        return Color(.systemGroupedBackground)
#elseif os(macOS)
        return Color(.controlBackgroundColor)
#endif
    }
    
    private var toolbarPlacement: ToolbarItemPlacement {
#if os(iOS)
        return .navigationBarTrailing
#elseif os(macOS)
        return .automatic
#endif
    }
    
    // MARK: - Methods
    
    private func checkExtensionStatus() {
        isCheckingExtension = true
        
#if os(macOS)
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: "com.ptmccarthy.WikiMapper.Extension") { state, error in
            DispatchQueue.main.async {
                self.isExtensionEnabled = state?.isEnabled ?? false
                self.isCheckingExtension = false
            }
        }
#else
        // On iOS, we can't directly check extension status
        // We'll assume it's enabled if we have data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isCheckingExtension = false
            // Check if we have any WikiMapper data
            let userDefaults = UserDefaults(suiteName: "group.wikimapper.storage") ?? UserDefaults.standard
            let allKeys = userDefaults.dictionaryRepresentation().keys
            self.isExtensionEnabled = allKeys.contains { key in
                key.hasPrefix("wikimapper_")
            }
        }
#endif
    }
    
#if os(macOS)
    private func openSafariExtensionPreferences() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.ptmccarthy.WikiMapper.Extension") { error in
            if let error = error {
                print("Error opening Safari preferences: \(error)")
            }
        }
    }
#endif
}

// MARK: - Supporting Views

/// Individual instruction step view
struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview {
    SafariExtensionGuideView()
}