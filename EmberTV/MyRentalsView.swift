import SwiftUI

// MARK: - Ember Capsule Button Style (outline → filled on focus)

struct EmberCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        EmberCapsuleButton(configuration: configuration)
    }

    private struct EmberCapsuleButton: View {
        @Environment(\.isFocused) private var isFocused: Bool
        let configuration: Configuration

        var body: some View {
            configuration.label
                .font(EmberTheme.bodySemibold(22))
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isFocused
                            ? EmberTheme.primary
                            : Color.clear
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            EmberTheme.primary,
                            lineWidth: 2
                        )
                )
                .foregroundColor(.white)
                .scaleEffect(isFocused || configuration.isPressed ? 1.06 : 1.0)
                .shadow(
                    color: isFocused ? EmberTheme.primary.opacity(0.7) : .clear,
                    radius: 14, x: 0, y: 0
                )
                .animation(.easeOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .focusEffectDisabled(true)
        }
    }
}

// MARK: - MyRentalsView

struct MyRentalsView: View {
    @EnvironmentObject var apiClient: EmberAPIClient

    @State private var rentals: [Rental] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let columns: [GridItem] = [
        GridItem(.fixed(260), spacing: 60),
        GridItem(.fixed(260), spacing: 60),
        GridItem(.fixed(260), spacing: 60),
        GridItem(.fixed(260), spacing: 60)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                EmberTheme.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 60) {

                    // Header
                    HStack {
                        Image("ember-tv-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .padding(.leading, 80)

                        Spacer()

                        VStack(spacing: 4) {
                            Text("My Rentals")
                                .font(EmberTheme.titleFont(40))
                                .foregroundColor(.white)

                            Text("Your active 24-hour rentals, ready to watch.")
                                .font(EmberTheme.bodyFont(18))
                                .foregroundColor(EmberTheme.textSecondary)
                        }

                        Spacer()

                        HStack(spacing: 16) {
                            Button {
                                Task { await reload() }
                            } label: {
                                Text("Refresh")
                            }
                            .buttonStyle(EmberCapsuleButtonStyle())

                            Button {
                                logout()
                            } label: {
                                Text("Log Out")
                            }
                            .buttonStyle(EmberCapsuleButtonStyle())
                        }
                        .padding(.trailing, 80)
                    }
                    .padding(.top, 60)
                    .focusSection()

                    // Main content
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(for: Rental.self) { rental in
                RentalDetailView(rental: rental)
            }
            .task {
                await reload()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isLoading && rentals.isEmpty {
            Spacer()
            ProgressView("Loading your rentals…")
                .font(EmberTheme.bodyFont(24))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        } else if let message = errorMessage, rentals.isEmpty {
            Spacer()
            VStack(spacing: 16) {
                Text("Something went wrong")
                    .font(EmberTheme.headingFont(32))
                    .foregroundColor(.white)

                Text(message)
                    .font(EmberTheme.bodyFont(20))
                    .foregroundColor(EmberTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 800)

                Button {
                    Task { await reload() }
                } label: {
                    Text("Try Again")
                        .font(EmberTheme.bodySemibold(22))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(EmberTheme.primary)
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        } else if rentals.isEmpty {
            Spacer()
            VStack(spacing: 16) {
                Text("No Active Rentals")
                    .font(EmberTheme.headingFont(32))
                    .foregroundColor(.white)

                Text("When you rent a film on Ember, it will appear here and stay active for 24 hours.")
                    .font(EmberTheme.bodyFont(20))
                    .foregroundColor(EmberTheme.textSecondary)
                    .frame(maxWidth: 900)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 60) {
                    ForEach(Array(rentals.enumerated()), id: \.offset) { _, rental in
                        NavigationLink(value: rental) {
                            RentalPosterCard(rental: rental)
                        }
                    }
                }
                .padding(.horizontal, 120)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .focusSection()
        }
    }

    // MARK: - Data

    private func reload() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let fetched = try await apiClient.fetchMyRentals()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    rentals = fetched
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "We couldn’t load your rentals. Please try again."
                isLoading = false
            }
        }
    }

    private func logout() {
        apiClient.logout()
        rentals = []
    }
}

