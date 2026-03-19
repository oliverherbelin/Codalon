// Issue #220 — Versions tab: HelaiaFrameworks versions, app version/build

import SwiftUI
import HelaiaDesign

// MARK: - FrameworkVersion

struct FrameworkVersion: Identifiable, Sendable {
    let id: String
    let name: String
    let version: String
}

// MARK: - VersionsTabView

struct VersionsTabView: View {

    // MARK: - State

    @State private var frameworkVersions: [FrameworkVersion] = VersionsTabView.defaultFrameworks

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "About Codalon",
                    subtitle: "Command center for solo developers."
                )

                appInfoSection
                frameworksSection
                systemSection
            }
            .padding(Spacing._6)
        }
    }

    // MARK: - App Info Section

    @ViewBuilder
    private var appInfoSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._3) {
                    HelaiaIconView("app.fill", size: .hero, color: .blue)
                    VStack(alignment: .leading, spacing: Spacing._1) {
                        Text("Codalon")
                            .helaiaFont(.title3)
                            .fontWeight(.bold)
                        Text("A Helaia product")
                            .helaiaFont(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HelaiaSettingsRow(
                    title: "Version",
                    icon: "tag.fill",
                    iconColor: .blue,
                    variant: .info(appVersion)
                )

                HelaiaSettingsRow(
                    title: "Build",
                    icon: "hammer.fill",
                    iconColor: .orange,
                    variant: .info(buildNumber)
                )
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Frameworks Section

    @ViewBuilder
    private var frameworksSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("HelaiaFrameworks")
                    .helaiaFont(.headline)

                ForEach(frameworkVersions) { fw in
                    HelaiaSettingsRow(
                        title: fw.name,
                        icon: "shippingbox.fill",
                        iconColor: .purple,
                        variant: .info(fw.version)
                    )
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - System Section

    @ViewBuilder
    private var systemSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("System")
                    .helaiaFont(.headline)

                HelaiaSettingsRow(
                    title: "macOS",
                    icon: "desktopcomputer",
                    iconColor: .gray,
                    variant: .info(macOSVersion)
                )

                HelaiaSettingsRow(
                    title: "Swift",
                    icon: "swift",
                    iconColor: .orange,
                    variant: .info("6.0")
                )
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private var macOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    // MARK: - Default Data

    private static let defaultFrameworks: [FrameworkVersion] = [
        FrameworkVersion(id: "core", name: "HelaiaCore", version: "1.0"),
        FrameworkVersion(id: "engine", name: "HelaiaEngine", version: "1.0"),
        FrameworkVersion(id: "design", name: "HelaiaDesign", version: "1.0"),
        FrameworkVersion(id: "storage", name: "HelaiaStorage", version: "1.0"),
        FrameworkVersion(id: "keychain", name: "HelaiaKeychain", version: "1.0"),
        FrameworkVersion(id: "ai", name: "HelaiaAI", version: "1.0"),
        FrameworkVersion(id: "analytics", name: "HelaiaAnalytics", version: "1.0"),
        FrameworkVersion(id: "git", name: "HelaiaGit", version: "1.0"),
        FrameworkVersion(id: "sync", name: "HelaiaSync", version: "1.0"),
        FrameworkVersion(id: "logger", name: "HelaiaLogger", version: "1.0"),
        FrameworkVersion(id: "notifications", name: "HelaiaNotify", version: "1.0"),
        FrameworkVersion(id: "sharing", name: "HelaiaShare", version: "1.0"),
    ]
}

// MARK: - Preview

#Preview("About / Versions") {
    VersionsTabView()
        .frame(width: 500, height: 700)
}
