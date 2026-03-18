// Issue #214 — Metadata status summary view

import SwiftUI
import HelaiaDesign

// MARK: - ASCMetadataStatusView

struct ASCMetadataStatusView: View {

    // MARK: - State

    @State private var viewModel: ASCViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ASCViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            Text("Metadata & Localizations")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            if let metadata = viewModel.metadataStatus {
                metadataSection(metadata)
            }

            if let localization = viewModel.localizationStatus {
                localizationSection(localization)
            }

            if viewModel.metadataStatus == nil && viewModel.localizationStatus == nil {
                HelaiaEmptyState(
                    icon: "doc.text",
                    title: "No metadata loaded",
                    description: "Link an ASC app and load build data to see metadata status"
                )
            }
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.loadMetadataStatus()
        }
    }

    // MARK: - Metadata Section

    @ViewBuilder
    private func metadataSection(_ metadata: ASCMetadataStatus) -> some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._3) {
                    HelaiaIconView(
                        "doc.text.fill",
                        size: .md,
                        color: metadata.completeness >= 1.0
                            ? SemanticColor.success(for: colorScheme)
                            : SemanticColor.warning(for: colorScheme)
                    )

                    VStack(alignment: .leading, spacing: Spacing._0_5) {
                        Text("Metadata Completeness")
                            .helaiaFont(.headline)
                        Text("\(Int(metadata.completeness * 100))%")
                            .helaiaFont(.caption1)
                            .foregroundStyle(
                                metadata.completeness >= 1.0
                                    ? SemanticColor.success(for: colorScheme)
                                    : SemanticColor.warning(for: colorScheme)
                            )
                    }

                    Spacer()
                }

                Divider()

                ForEach(metadata.fields) { field in
                    fieldRow(field)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldRow(_ field: ASCMetadataField) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                field.isComplete ? "checkmark.circle.fill" : "xmark.circle.fill",
                size: .xs,
                color: field.isComplete
                    ? SemanticColor.success(for: colorScheme)
                    : SemanticColor.error(for: colorScheme)
            )

            Text(field.label)
                .helaiaFont(.footnote)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            Spacer()

            if !field.isComplete {
                Text("Missing")
                    .helaiaFont(.tag)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(field.label): \(field.isComplete ? "Complete" : "Missing")")
    }

    // MARK: - Localization Section

    @ViewBuilder
    private func localizationSection(_ localization: ASCLocalizationStatus) -> some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._3) {
                    HelaiaIconView(
                        "globe",
                        size: .md,
                        color: localization.overallCompleteness >= 1.0
                            ? SemanticColor.success(for: colorScheme)
                            : SemanticColor.warning(for: colorScheme)
                    )

                    VStack(alignment: .leading, spacing: Spacing._0_5) {
                        Text("Localization Completeness")
                            .helaiaFont(.headline)
                        Text("\(Int(localization.overallCompleteness * 100))% across \(localization.locales.count) locale\(localization.locales.count == 1 ? "" : "s")")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    }

                    Spacer()
                }

                if !localization.locales.isEmpty {
                    Divider()

                    ForEach(localization.locales) { locale in
                        localeRow(locale)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func localeRow(_ locale: ASCLocaleCompleteness) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                locale.completeness >= 1.0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                size: .xs,
                color: locale.completeness >= 1.0
                    ? SemanticColor.success(for: colorScheme)
                    : SemanticColor.warning(for: colorScheme)
            )

            Text(locale.locale)
                .helaiaFont(.footnote)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            Spacer()

            Text("\(Int(locale.completeness * 100))%")
                .helaiaFont(.caption1)
                .foregroundStyle(
                    locale.completeness >= 1.0
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.warning(for: colorScheme)
                )

            if !locale.missingFields.isEmpty {
                Text("\(locale.missingFields.count) missing")
                    .helaiaFont(.tag)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }
        }
    }
}

// MARK: - Preview

#Preview("ASCMetadataStatusView — Partial") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.linkedApp = ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS)
    vm.metadataStatus = ASCMetadataStatus(fields: [
        ASCMetadataField(id: "name", label: "App Name", isComplete: true, value: "Codalon"),
        ASCMetadataField(id: "subtitle", label: "Subtitle", isComplete: true, value: "Dev Command Center"),
        ASCMetadataField(id: "description", label: "Description", isComplete: true, value: "Full desc..."),
        ASCMetadataField(id: "keywords", label: "Keywords", isComplete: true, value: "developer,tools"),
        ASCMetadataField(id: "supportUrl", label: "Support URL", isComplete: true, value: "https://..."),
        ASCMetadataField(id: "marketingUrl", label: "Marketing URL", isComplete: false),
        ASCMetadataField(id: "privacyPolicyUrl", label: "Privacy Policy URL", isComplete: false),
    ])
    vm.localizationStatus = ASCLocalizationStatus(locales: [
        ASCLocaleCompleteness(locale: "en-US", completeness: 1.0),
        ASCLocaleCompleteness(locale: "de-DE", completeness: 0.6, missingFields: ["keywords", "whatsNew"]),
        ASCLocaleCompleteness(locale: "fr-FR", completeness: 0.4, missingFields: ["description", "keywords", "whatsNew"]),
    ])

    return ASCMetadataStatusView(viewModel: vm)
        .frame(width: 500)
}

#Preview("ASCMetadataStatusView — Empty") {
    ASCMetadataStatusView(viewModel: ASCViewModel(
        ascService: PreviewASCService(),
        projectID: UUID()
    ))
    .frame(width: 500, height: 200)
}
