// Issue #258 — First-launch onboarding experience

import SwiftUI
import HelaiaDesign

// MARK: - OnboardingView

struct OnboardingView: View {

    let onComplete: () -> Void

    @State private var currentStep = 0
    @Environment(\.colorScheme) private var colorScheme

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "shippingbox.fill",
            title: "Welcome to Codalon",
            description: "Your macOS command center for solo development. One cockpit for GitHub, App Store Connect, planning, releases, and analytics.",
            hint: nil
        ),
        OnboardingStep(
            icon: "folder.fill",
            title: "Create a Project",
            description: "Start by creating a project. Choose your platform, set a name, and Codalon will track everything from milestones to releases.",
            hint: "You can manage multiple projects and switch between them anytime."
        ),
        OnboardingStep(
            icon: "link",
            title: "Connect Your Services",
            description: "Link GitHub to sync issues, milestones, and pull requests. Connect App Store Connect to track builds and metadata.",
            hint: "Go to Settings to connect GitHub and ASC when you're ready."
        ),
        OnboardingStep(
            icon: "chart.bar.fill",
            title: "Track Everything Locally",
            description: "Analytics, insights, and health scores — all stored locally on this device. No data ever leaves your Mac.",
            hint: nil
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            stepContent

            Spacer()

            navigation
        }
        .frame(width: 520, height: 420)
        .background(SemanticColor.background(for: colorScheme))
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        let step = steps[currentStep]

        VStack(spacing: Spacing._6) {
            HelaiaIconView(
                step.icon,
                size: .custom(48),
                color: SemanticColor.info(for: colorScheme)
            )

            VStack(spacing: Spacing._3) {
                Text(step.title)
                    .helaiaFont(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(step.description)
                    .helaiaFont(.body)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)

                if let hint = step.hint {
                    Text(hint)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing._1)
                }
            }
        }
        .padding(.horizontal, Spacing._8)
    }

    // MARK: - Navigation

    @ViewBuilder
    private var navigation: some View {
        VStack(spacing: Spacing._4) {
            // Progress dots
            HStack(spacing: Spacing._2) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(
                            index == currentStep
                                ? SemanticColor.info(for: colorScheme)
                                : SemanticColor.border(for: colorScheme)
                        )
                        .frame(width: 8, height: 8)
                }
            }

            // Buttons
            HStack(spacing: Spacing._3) {
                if currentStep > 0 {
                    HelaiaButton("Back", variant: .ghost) {
                        withAnimation { currentStep -= 1 }
                    }
                    .fixedSize()
                }

                Spacer()

                HelaiaButton("Skip", variant: .ghost) {
                    onComplete()
                }
                .fixedSize()

                if currentStep < steps.count - 1 {
                    HelaiaButton("Next", icon: .sfSymbol("arrow.right")) {
                        withAnimation { currentStep += 1 }
                    }
                    .fixedSize()
                } else {
                    HelaiaButton("Get Started", icon: .sfSymbol("arrow.right")) {
                        onComplete()
                    }
                    .fixedSize()
                }
            }
            .padding(.horizontal, Spacing._6)
            .padding(.bottom, Spacing._6)
        }
    }
}

// MARK: - OnboardingStep

private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let hint: String?
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView {
        print("Onboarding complete")
    }
}
