import SwiftUI

struct RentalDetailView: View {
    let rental: Rental

    @State private var showPlayer = false

    private var film: RentalFilmSummary { rental.film }

    // MARK: - Resume logic

    private var resumeSeconds: TimeInterval? {
        PlaybackProgressStore.progress(for: film.id)
    }

    private var totalDurationSeconds: TimeInterval? {
        guard let minutes = film.durationMinutes else { return nil }
        return TimeInterval(minutes * 60)
    }

    private var watchedPercent: Int? {
        guard
            let resume = resumeSeconds,
            let total = totalDurationSeconds,
            total > 0
        else { return nil }

        return Int((resume / total) * 100)
    }

    private var primaryButtonTitle: String {
        if let resume = resumeSeconds, resume > 60 {
            return "Resume"
        } else {
            return "Watch Now"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            EmberTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 60) {

                // Logo header
                HStack {
                    Image("ember-tv-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .padding(.leading, 80)

                    Spacer()
                }
                .padding(.top, 60)

                // Main content
                HStack(alignment: .top, spacing: 80) {

                    // Poster card
                    RentalPosterHero(film: film)
                        .padding(.leading, 80)

                    // Details
                    VStack(alignment: .leading, spacing: 28) {
                        Text(film.title)
                            .font(EmberTheme.titleFont(48))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 20) {
                            if let minutes = film.durationMinutes {
                                Label("\(minutes) min", systemImage: "clock")
                                    .font(EmberTheme.bodyFont(22))
                                    .foregroundColor(EmberTheme.textSecondary)
                            }

                            if let genre = film.genre, !genre.isEmpty {
                                Text(genre)
                                    .font(EmberTheme.bodyFont(20))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.08))
                                    )
                            }
                        }

                        if let long = film.longDescription, !long.isEmpty {
                            ScrollView {
                                Text(long)
                                    .font(EmberTheme.bodyFont(20))
                                    .foregroundColor(EmberTheme.textSecondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: 700, alignment: .leading)
                            }
                            .frame(maxHeight: 220)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                showPlayer = true
                            } label: {
                                HStack(spacing: 12) {
                                    if let resume = resumeSeconds, resume > 60 {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 24, weight: .bold))
                                    }
                                    Text(primaryButtonTitle)
                                        .font(EmberTheme.bodySemibold(24))
                                }
                            }
                            .buttonStyle(EmberPrimaryPillButtonStyle())

                            if let resume = resumeSeconds, resume > 60 {
                                if let percent = watchedPercent {
                                    Text("Resume from where you left off · about \(percent)% watched.")
                                        .font(EmberTheme.bodyFont(20))
                                        .foregroundColor(EmberTheme.textSecondary)
                                } else {
                                    let minutes = Int(resume / 60)
                                    Text("Resume from about \(minutes) minutes in.")
                                        .font(EmberTheme.bodyFont(20))
                                        .foregroundColor(EmberTheme.textSecondary)
                                }
                            } else {
                                Text("You’ll have 24 hours of access until your rental expires.")
                                    .font(EmberTheme.bodyFont(20))
                                    .foregroundColor(EmberTheme.textSecondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.trailing, 100)
                    .padding(.top, 40) // nudges text block down to align with poster

                    Spacer()
                }

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView(rental: rental, resumeFrom: resumeSeconds)
        }
    }
}

// MARK: - Poster hero

private struct RentalPosterHero: View {
    let film: RentalFilmSummary

    private let width: CGFloat = 260
    private let height: CGFloat = 430

    var body: some View {
        VStack(spacing: 0) {
            AsyncImage(url: film.posterURL) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.6))
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.6))
                        Image(systemName: "film")
                            .font(.system(size: 52))
                            .foregroundColor(.white.opacity(0.7))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(EmberTheme.primary, lineWidth: 2)
        )
    }
}

// MARK: - Primary pill button

struct EmberPrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        EmberPrimaryPillButton(configuration: configuration)
    }

    private struct EmberPrimaryPillButton: View {
        @Environment(\.isFocused) private var isFocused: Bool
        let configuration: Configuration

        var body: some View {
            configuration.label
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(EmberTheme.primary)
                )
                .foregroundColor(.white)
                .scaleEffect(isFocused || configuration.isPressed ? 1.06 : 1.0)
                .shadow(
                    color: isFocused ? EmberTheme.primary.opacity(0.7) : .clear,
                    radius: 16, x: 0, y: 0
                )
                .animation(.easeOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .focusEffectDisabled(true)
        }
    }
}

