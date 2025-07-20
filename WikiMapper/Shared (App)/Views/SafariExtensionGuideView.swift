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
    @Environment(SafariExtensionMonitor.self) private var extensionMonitor
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    #if os(macOS)
                    // Status indicator
                    statusSection
                    #endif
                    
                    // Instructions
                    instructionsSection
                    
                    // Action buttons
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Safari Extension Setup")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
#endif
        }
        .task {
            await extensionMonitor.checkExtensionStatus()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "safari")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            
            Text("Enable WikiMapper Extension")
                .font(.title)
                .bold()
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
            Image(systemName: extensionMonitor.isExtensionEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(extensionMonitor.isExtensionEnabled ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Extension Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(extensionMonitor.isExtensionEnabled ? "Enabled" : "Disabled")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(extensionMonitor.isExtensionEnabled ? .green : .orange)
            }
            
            Spacer()
            
            Button("Recheck") {
                Task {
                    await extensionMonitor.checkExtensionStatus()
                }
            }
            .disabled(extensionMonitor.isChecking)
        }
        .padding()
        .background(.fill.quaternary, in: .rect(cornerRadius: 12))
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
                description: "Open the Settings app and search for \"Safari\""
            )

            InstructionStep(
                number: 2,
                title: "Find Extensions Option",
                description: "In the Safari settings page, tap \"Extensions\""
            )

            InstructionStep(
                number: 3,
                title: "Enable WikiMapper",
                description: "Find WikiMapper in the list and turn on the toggle to enable it"
            )

            InstructionStep(
                number: 4,
                title: "Grant Permissions",
                description: "Allow WikiMapper to access Wikipedia sites as requested"
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
            Button("Open Safari Extension Preferences") {
#if os(macOS)
                Task {
                    await openSafariExtensionPreferences()
                }
#else
                openURL(URL(string: "App-Prefs:com.apple.mobilesafari&path=WEB_EXTENSIONS")!)
#endif
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
    
    // MARK: - Methods
    
#if os(macOS)
    private func openSafariExtensionPreferences() async {
        try? await SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.ptmccarthy.WikiMapper.Extension")
    }
#endif
}

// MARK: - Supporting Views

/// Individual instruction step view
struct InstructionStep: View {
    let number: Int
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    
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
        .environment(SafariExtensionMonitor())
}
