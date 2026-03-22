// Issue #258 — First-launch onboarding (First Launch & Onboarding Spec v1.0)

import SwiftUI
import UniformTypeIdentifiers
import HelaiaDesign
import HelaiaEngine
import HelaiaKeychain
import HelaiaAI

// MARK: - OnboardingStep

enum OnboardingStep: Sendable, Equatable {
    case connectIntegrations
    case nameProject
    case chooseContext
}

// MARK: - OnboardingView

struct OnboardingView: View {

    let onComplete: (CodalonProject, CodalonContext, URL?, ProjectCreationSideEffects) -> Void

    @State private var step: OnboardingStep = .connectIntegrations
    @State private var cardVisible = false

    // Integration state
    @State private var gitHubConnected = false
    @State private var gitHubUsername = ""
    @State private var ascConnected = false
    @State private var aiConnected = false

    // Project state
    @State private var createdProject: CodalonProject?
    @State private var localFolderURL: URL?
    @State private var creationSideEffects = ProjectCreationSideEffects()

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                switch step {
                case .connectIntegrations:
                    ConnectIntegrationsStep(
                        gitHubConnected: $gitHubConnected,
                        gitHubUsername: $gitHubUsername,
                        ascConnected: $ascConnected,
                        aiConnected: $aiConnected,
                        onContinue: { advanceTo(.nameProject) }
                    )
                    .transition(stepTransition)

                case .nameProject:
                    ProjectCreationFlow(
                        gitHubConnected: gitHubConnected,
                        onBack: { advanceTo(.connectIntegrations) },
                        onComplete: { project, url, sideEffects in
                            createdProject = project
                            localFolderURL = url
                            creationSideEffects = sideEffects
                            advanceTo(.chooseContext)
                        }
                    )
                    .transition(stepTransition)

                case .chooseContext:
                    ChooseContextStep(
                        gitHubConnected: gitHubConnected,
                        selectedRepoFullName: createdProject?.linkedGitHubRepos.first,
                        onBack: { advanceTo(.nameProject) },
                        onSelect: { context in
                            guard let project = createdProject else { return }
                            dismissCard(context: context, project: project)
                        }
                    )
                    .transition(stepTransition)
                }
            }
            .padding(Spacing._8)
            .frame(width: 560)
            .frame(minHeight: 440, maxHeight: 560)
            .background {
                HelaiaMaterial.thick.apply(to: Color.clear)
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.twoXl))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.twoXl)
                    .stroke(
                        SemanticColor.border(for: colorScheme).opacity(Opacity.State.hover),
                        lineWidth: BorderWidth.hairline
                    )
            }
            .helaiaShadow(.xl, colorScheme: colorScheme)
            .scaleEffect(cardVisible ? 1.0 : ComponentAnimation.Card.pressScale)
            .opacity(cardVisible ? Opacity.full : Opacity.none)
            .animation(
                reduceMotion
                    ? .easeInOut(duration: AnimationDuration.normal)
                    : .spring(response: 0.4, dampingFraction: 0.82),
                value: cardVisible
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.slow) {
                cardVisible = true
            }
        }
    }

    // MARK: - Navigation

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity.animation(.easeInOut(duration: AnimationDuration.normal))
        }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: Spacing._4))
                .animation(.easeOut(duration: AnimationDuration.normal)),
            removal: .opacity.combined(with: .offset(y: -Spacing._4))
                .animation(.easeIn(duration: AnimationDuration.fast))
        )
    }

    private func advanceTo(_ newStep: OnboardingStep) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            step = newStep
        }
    }

    private func dismissCard(context: CodalonContext, project: CodalonProject) {
        withAnimation(.easeIn(duration: AnimationDuration.slow)) {
            cardVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.slower) {
            onComplete(project, context, localFolderURL, creationSideEffects)
        }
    }
}

// MARK: - Step 1: Connect Integrations

private struct ConnectIntegrationsStep: View {

    @Binding var gitHubConnected: Bool
    @Binding var gitHubUsername: String
    @Binding var ascConnected: Bool
    @Binding var aiConnected: Bool
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Inline expansion
    @State private var expandedRow: IntegrationRow?
    @State private var gitHubToken = ""
    @State private var gitHubError: String?
    @State private var gitHubValidating = false
    @State private var ascIssuerID = ""
    @State private var ascKeyID = ""
    @State private var ascPrivateKey = ""
    @State private var ascError: String?
    @State private var ascValidating = false
    @State private var aiProvider: CodalonAIProvider = .anthropic
    @State private var aiKey = ""
    @State private var aiBaseURL = "http://localhost:11434"
    @State private var aiError: String?
    @State private var aiValidating = false

    private enum IntegrationRow: Equatable {
        case gitHub, asc, ai
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                Text("Welcome to Codalon")
                    .helaiaFont(.title2)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    .padding(.top, Spacing._3)

                Text("Connect your tools — or skip and connect later from Settings.")
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing._1_5)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing._6)

            // Integration rows
            VStack(spacing: 0) {
                gitHubRow
                separator
                ascRow
                separator
                aiRow
            }

            Spacer(minLength: Spacing._4)

            // Footer
            HelaiaButton(
                gitHubConnected || ascConnected || aiConnected ? "Continue" : "Continue",
                icon: "arrow.right",
                fullWidth: true
            ) {
                onContinue()
            }
        }
    }

    // MARK: - Separator

    private var separator: some View {
        Rectangle()
            .fill(SemanticColor.border(for: colorScheme))
            .frame(height: BorderWidth.hairline)
    }

    // MARK: - GitHub Row

    @ViewBuilder
    private var gitHubRow: some View {
        integrationRowHeader(
            icon: "lock.shield.fill",
            name: "GitHub",
            descriptor: "Access repositories, issues, and pull requests",
            isConnected: gitHubConnected,
            row: .gitHub
        )

        if expandedRow == .gitHub {
            VStack(alignment: .leading, spacing: Spacing._2) {
                HelaiaSecureField(
                    title: "",
                    text: $gitHubToken,
                    placeholder: "ghp_xxxxxxxxxxxx",
                    state: gitHubError.map { .error(message: $0) } ?? .idle,
                    helperText: "Required scopes: repo, read:user"
                )

                HStack(spacing: Spacing._2) {
                    HelaiaButton(
                        "Validate & Connect",
                        variant: .primary,
                        size: .small,
                        isLoading: gitHubValidating,
                        fullWidth: false
                    ) {
                        validateGitHub()
                    }
                    .disabled(gitHubToken.isEmpty || gitHubValidating)

                    HelaiaButton(
                        "Cancel",
                        variant: .ghost,
                        size: .small,
                        fullWidth: false
                    ) {
                        withAnimation(ComponentAnimation.Card.press) {
                            expandedRow = nil
                        }
                    }
                }
            }
            .padding(.leading, Spacing._10)
            .padding(.trailing, Spacing._2)
            .padding(.bottom, Spacing._3)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - ASC Row

    @ViewBuilder
    private var ascRow: some View {
        integrationRowHeader(
            icon: "app.badge.fill",
            name: "App Store Connect",
            descriptor: "Access builds, TestFlight, reviews, and sales",
            isConnected: ascConnected,
            row: .asc
        )

        if expandedRow == .asc {
            VStack(alignment: .leading, spacing: Spacing._2) {
                HelaiaTextField(
                    title: "Issuer ID",
                    text: $ascIssuerID,
                    placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
                )

                HelaiaTextField(
                    title: "Key ID",
                    text: $ascKeyID,
                    placeholder: "XXXXXXXXXX"
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("Private Key (.p8)")
                        .helaiaFont(.subheadline)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                    TextEditor(text: $ascPrivateKey)
                        .helaiaFont(.caption1)
                        .frame(height: 80)
                        .overlay {
                            if ascPrivateKey.isEmpty {
                                Text("Paste .p8 key contents here")
                                    .helaiaFont(.caption1)
                                    .foregroundStyle(
                                        SemanticColor.textTertiary(for: colorScheme)
                                    )
                                    .allowsHitTesting(false)
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: .infinity,
                                        alignment: .topLeading
                                    )
                                    .padding(Spacing._1)
                            }
                        }
                        .background(SemanticColor.surface(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(
                                    SemanticColor.border(for: colorScheme),
                                    lineWidth: BorderWidth.thin
                                )
                        }
                }

                HelaiaButton.ghost("Import from .p8 file", icon: "doc") {
                    importP8File()
                }

                if let error = ascError {
                    Text(error)
                        .helaiaFont(.caption2)
                        .foregroundStyle(SemanticColor.error(for: colorScheme))
                }

                HStack(spacing: Spacing._2) {
                    HelaiaButton(
                        "Validate & Connect",
                        variant: .primary,
                        size: .small,
                        isLoading: ascValidating,
                        fullWidth: false
                    ) {
                        validateASC()
                    }
                    .disabled(
                        ascIssuerID.isEmpty || ascKeyID.isEmpty
                            || ascPrivateKey.isEmpty || ascValidating
                    )

                    HelaiaButton(
                        "Cancel",
                        variant: .ghost,
                        size: .small,
                        fullWidth: false
                    ) {
                        withAnimation(ComponentAnimation.Card.press) {
                            expandedRow = nil
                        }
                    }
                }
            }
            .padding(.leading, Spacing._10)
            .padding(.trailing, Spacing._2)
            .padding(.bottom, Spacing._3)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - AI Row

    @ViewBuilder
    private var aiRow: some View {
        integrationRowHeader(
            icon: aiProvider.iconName,
            name: "AI Assistant",
            descriptor: "Operational insights and analysis (BYOK)",
            isConnected: aiConnected,
            row: .ai
        )

        if expandedRow == .ai {
            VStack(alignment: .leading, spacing: Spacing._2) {
                // Provider selector pills
                HStack(spacing: Spacing._1_5) {
                    ForEach(CodalonAIProvider.allCases) { provider in
                        HelaiaCapsule.filter(
                            provider.displayName,
                            icon: .sfSymbol(provider.iconName),
                            isSelected: aiProvider == provider
                        ) {
                            aiProvider = provider
                            aiKey = ""
                            aiError = nil
                        }
                    }
                }

                if aiProvider == .ollama {
                    HelaiaTextField(
                        title: "",
                        text: $aiBaseURL,
                        placeholder: "http://localhost:11434",
                        state: aiError.map { .error(message: $0) } ?? .idle
                    )
                } else {
                    let placeholder = aiProvider == .anthropic ? "sk-ant-..." : "sk-..."
                    HelaiaSecureField(
                        title: "",
                        text: $aiKey,
                        placeholder: placeholder,
                        state: aiError.map { .error(message: $0) } ?? .idle
                    )
                }

                HStack(spacing: Spacing._2) {
                    HelaiaButton(
                        "Validate & Connect",
                        variant: .primary,
                        size: .small,
                        isLoading: aiValidating,
                        fullWidth: false
                    ) {
                        validateAI()
                    }
                    .disabled(
                        (aiProvider == .ollama ? aiBaseURL.isEmpty : aiKey.isEmpty)
                            || aiValidating
                    )

                    HelaiaButton(
                        "Cancel",
                        variant: .ghost,
                        size: .small,
                        fullWidth: false
                    ) {
                        withAnimation(ComponentAnimation.Card.press) {
                            expandedRow = nil
                        }
                    }
                }
            }
            .padding(.leading, Spacing._10)
            .padding(.trailing, Spacing._2)
            .padding(.bottom, Spacing._3)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Integration Row Header

    @ViewBuilder
    private func integrationRowHeader(
        icon: String,
        name: String,
        descriptor: String,
        isConnected: Bool,
        row: IntegrationRow
    ) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                icon,
                size: .custom(28),
                color: SemanticColor.textSecondary(for: colorScheme)
            )

            VStack(alignment: .leading, spacing: Spacing._px) {
                Text(name)
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                Text(descriptor)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            }

            Spacer()

            if isConnected {
                Text("Connected")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.success(for: colorScheme))

                HelaiaButton(
                    "Edit",
                    variant: .ghost,
                    size: .small,
                    fullWidth: false
                ) {
                    withAnimation(ComponentAnimation.Card.press) {
                        expandedRow = expandedRow == row ? nil : row
                    }
                }
            } else {
                HelaiaButton(
                    "Connect",
                    variant: .secondary,
                    size: .small,
                    fullWidth: false
                ) {
                    withAnimation(ComponentAnimation.Card.press) {
                        expandedRow = expandedRow == row ? nil : row
                    }
                }
            }
        }
        .frame(height: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(name) integration, \(isConnected ? "connected" : "not connected")"
        )
        .accessibilityAction(
            named: isConnected ? "Edit \(name)" : "Connect \(name)"
        ) {
            withAnimation(ComponentAnimation.Card.press) {
                expandedRow = expandedRow == row ? nil : row
            }
        }
    }

    // MARK: - Validation Actions

    private func validateGitHub() {
        gitHubValidating = true
        gitHubError = nil

        Task {
            do {
                // Validate token by fetching /user
                let url = URL(string: "https://api.github.com/user")!
                var request = URLRequest(url: url)
                request.setValue(
                    "Bearer \(gitHubToken)",
                    forHTTPHeaderField: "Authorization"
                )
                request.setValue(
                    "application/vnd.github+json",
                    forHTTPHeaderField: "Accept"
                )
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200 else {
                    throw OnboardingError.gitHubAuthFailed
                }
                let user = try JSONDecoder().decode(GitHubUser.self, from: data)

                // Store via GitHubService so GitCredentialManager
                // persists in the correct format for later retrieval
                let container = ServiceContainer.shared
                let gitHubService = try await container.resolve(
                    (any GitHubServiceProtocol).self
                )
                try await gitHubService.authenticate(
                    token: gitHubToken,
                    username: user.login
                )

                await MainActor.run {
                    gitHubUsername = user.login
                    gitHubConnected = true
                    gitHubValidating = false
                    withAnimation(ComponentAnimation.Card.press) {
                        expandedRow = nil
                    }
                }
            } catch {
                await MainActor.run {
                    gitHubError = "Invalid token or insufficient scopes."
                    gitHubValidating = false
                }
            }
        }
    }

    private func validateASC() {
        ascValidating = true
        ascError = nil

        Task {
            do {
                let container = ServiceContainer.shared
                if let service = await container.resolveOptional(
                    (any ASCCredentialServiceProtocol).self
                ) {
                    let credential = ASCCredential(
                        issuerID: ascIssuerID.trimmingCharacters(in: .whitespaces),
                        keyID: ascKeyID.trimmingCharacters(in: .whitespaces),
                        privateKey: ascPrivateKey
                    )
                    try await service.save(credential)
                }

                await MainActor.run {
                    ascConnected = true
                    ascValidating = false
                    withAnimation(ComponentAnimation.Card.press) {
                        expandedRow = nil
                    }
                }
            } catch {
                await MainActor.run {
                    ascError = "Invalid credentials. Check Issuer ID, Key ID, and private key."
                    ascValidating = false
                }
            }
        }
    }

    private func validateAI() {
        aiValidating = true
        aiError = nil

        Task {
            do {
                let container = ServiceContainer.shared
                let keychain = try await container.resolve(
                    (any KeychainServiceProtocol).self
                )

                if aiProvider == .ollama {
                    guard let url = URL(
                        string: aiBaseURL.trimmingCharacters(in: .whitespaces)
                    ) else {
                        throw OnboardingError.invalidURL
                    }
                    let (_, response) = try await URLSession.shared.data(from: url)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        throw OnboardingError.ollamaUnreachable
                    }
                    try await keychain.save(
                        aiBaseURL,
                        for: "com.helaia.ai.ollama.baseURL",
                        options: KeychainItemOptions(
                            accessibility: .whenUnlockedThisDeviceOnly
                        )
                    )
                } else {
                    let key = aiProvider == .anthropic
                        ? "com.helaia.ai.anthropic.apiKey"
                        : "com.helaia.ai.openai.apiKey"
                    try await keychain.save(
                        aiKey,
                        for: key,
                        options: KeychainItemOptions(
                            accessibility: .whenUnlockedThisDeviceOnly
                        )
                    )
                }

                await MainActor.run {
                    aiConnected = true
                    aiValidating = false
                    withAnimation(ComponentAnimation.Card.press) {
                        expandedRow = nil
                    }
                }
            } catch is OnboardingError {
                await MainActor.run {
                    aiError = aiProvider == .ollama
                        ? "Cannot reach Ollama at \(aiBaseURL)."
                        : "Invalid API key."
                    aiValidating = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Invalid API key."
                    aiValidating = false
                }
            }
        }
    }

    private func importP8File() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "p8") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            if let contents = try? String(contentsOf: url, encoding: .utf8) {
                ascPrivateKey = contents
            }
        }
    }
}

// MARK: - Step 3: Choose Your Starting Context

private struct ChooseContextStep: View {

    let gitHubConnected: Bool
    let selectedRepoFullName: String?
    let onBack: () -> Void
    let onSelect: (CodalonContext) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var suggestion: CodalonContext?
    @State private var tappedContext: CodalonContext?

    private let options: [(CodalonContext, String)] = [
        (.development, "Focus on tasks, milestones, and git activity"),
        (.release, "Manage builds, readiness, and submission"),
        (.launch, "Monitor crashes, reviews, and distribution"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing._1_5) {
                Text("How do you want to start?")
                    .helaiaFont(.title2)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                Text("Codalon will update this automatically as your project evolves.")
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing._5)

            // Smart suggestion
            if let suggested = suggestion {
                smartSuggestionBlock(context: suggested)
                    .padding(.bottom, Spacing._4)
            }

            // Context cards
            VStack(spacing: Spacing._3) {
                ForEach(options, id: \.0) { context, descriptor in
                    contextCard(context: context, descriptor: descriptor)
                }
            }

            Spacer(minLength: Spacing._4)

            // Footer — back only
            HStack {
                HelaiaButton.ghost("Back", icon: "chevron.left") {
                    onBack()
                }
                Spacer()
            }
        }
        .task { await detectSuggestion() }
    }

    // MARK: - Smart Suggestion

    @ViewBuilder
    private func smartSuggestionBlock(context: CodalonContext) -> some View {
        let tint = context.theme.color(for: colorScheme)

        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                context.iconName,
                size: .sm,
                color: tint
            )

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text("Looks like you're actively developing.")
                    .helaiaFont(.bodyEmphasized)
                Text("We suggest starting in \(context.displayName) Mode.")
                    .helaiaFont(.body)
            }
            .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
        }
        .padding(Spacing._3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(tint.opacity(Opacity.State.hover))
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(tint, lineWidth: BorderWidth.hairline)
        }
    }

    // MARK: - Context Card

    @ViewBuilder
    private func contextCard(context: CodalonContext, descriptor: String) -> some View {
        let isTapped = tappedContext == context
        let tint = context.theme.color(for: colorScheme)

        Button {
            tappedContext = context
            withAnimation(ComponentAnimation.Card.press) {}
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.fast) {
                onSelect(context)
            }
        } label: {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    context.iconName,
                    size: .xl,
                    color: tint
                )

                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    Text(context.displayName)
                        .helaiaFont(.button)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                    Text(descriptor)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing._4)
            .frame(height: 64)
            .background {
                HelaiaMaterial.regular.apply(to: Color.clear)
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .scaleEffect(isTapped ? ComponentAnimation.Card.pressScale : 1.0)
            .animation(ComponentAnimation.Card.press, value: isTapped)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(context.displayName): \(descriptor)")
        .accessibilityAction(named: "Start in \(context.displayName) mode") {
            onSelect(context)
        }
    }

    // MARK: - Signal Detection

    private func detectSuggestion() async {
        guard gitHubConnected, let fullName = selectedRepoFullName else { return }
        let parts = fullName.components(separatedBy: "/")
        guard parts.count == 2 else { return }

        do {
            let container = ServiceContainer.shared
            let gitHubService = try await container.resolve(
                (any GitHubServiceProtocol).self
            )

            let issues = try await gitHubService.fetchIssues(
                owner: parts[0],
                repo: parts[1],
                state: "open"
            )

            await MainActor.run {
                suggestion = issues.isEmpty ? .launch : .development
            }
        } catch {
            // No suggestion if API fails
        }
    }
}

// MARK: - Error Type

private enum OnboardingError: Error {
    case invalidURL
    case ollamaUnreachable
    case gitHubAuthFailed
}

// MARK: - Previews

#Preview("Onboarding — Step 1") {
    ZStack {
        AmbientLayer()
        OnboardingView { _, _, _, _ in }
    }
    .frame(width: 1200, height: 760)
    .environment(\.projectContext, .development)
}
