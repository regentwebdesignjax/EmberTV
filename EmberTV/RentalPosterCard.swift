import SwiftUI

struct RentalPosterCard: View {
    let rental: Rental

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Poster
            AsyncImage(url: rental.film.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Color.black.opacity(0.6)
                        .overlay(
                            Image(systemName: "film")
                                .font(.system(size: 40, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        )
                case .empty:
                    Color.black.opacity(0.6)
                        .overlay(ProgressView())
                @unknown default:
                    Color.black
                }
            }
            .frame(width: 230, height: 340)
            .clipped()

            // Bottom text panel (title + meta)
            VStack(alignment: .leading, spacing: 4) {
                Text(rental.film.title)
                    .font(EmberTheme.bodySemibold(18))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let expiresAt = rental.expiresAt {
                    Text(expirationText(from: expiresAt))
                        .font(EmberTheme.captionFont(14))
                        .opacity(0.9)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isFocused ? EmberTheme.primary : Color.clear
            )
            .foregroundColor(isFocused ? Color.white : EmberTheme.textPrimary)
        }
        .frame(width: 230, height: 410)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(EmberTheme.primary, lineWidth: 2)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.18), value: isFocused)
        .focusable(true)
        .focused($isFocused)
        .focusEffectDisabled(true) // disable default white tvOS focus
    }

    private func expirationText(from date: Date) -> String {
        let remaining = date.timeIntervalSinceNow
        guard remaining > 0 else { return "Expired" }

        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "Expires in \(hours) hr, \(minutes) min"
        } else {
            return "Expires in \(minutes) min"
        }
    }
}

