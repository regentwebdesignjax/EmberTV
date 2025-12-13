import SwiftUI

struct LoginView: View {
    @EnvironmentObject var api: EmberAPIClient

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            EmberTheme.background
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 40) {
                    // Logo
                    Image("ember-tv-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)

                    // Title + subtitle
                    VStack(spacing: 12) {
                        Text("Sign in to EmberTV")
                            .font(EmberTheme.titleFont(44))
                            .foregroundColor(.white)

                        Text("Use the same email and password you use on EmberStreaming.app.")
                            .font(EmberTheme.bodyFont(22))
                            .foregroundColor(EmberTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 900)
                    }

                    // Form card
                    VStack(spacing: 24) {

                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(EmberTheme.bodyFont(20))
                                .foregroundColor(EmberTheme.textSecondary)

                            TextField("name@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(EmberTheme.bodyFont(22))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(EmberTheme.primary.opacity(0.9), lineWidth: 2)
                                )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(EmberTheme.bodyFont(20))
                                .foregroundColor(EmberTheme.textSecondary)

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .font(EmberTheme.bodyFont(22))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(EmberTheme.primary.opacity(0.9), lineWidth: 2)
                                )
                        }

                        // Error message
                        if let errorMessage {
                            Text(errorMessage)
                                .font(EmberTheme.bodyFont(20))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 700)
                        }

                        // Sign In button
                        Button {
                            Task { await login() }
                        } label: {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 26, weight: .bold))
                                }
                                Text(isLoading ? "Signing In…" : "Sign In")
                                    .font(EmberTheme.bodySemibold(24))
                            }
                        }
                        .buttonStyle(EmberLoginPrimaryButtonStyle())
                        // IMPORTANT: no .disabled based on fields so we can prove the call works
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
                    .frame(maxWidth: 900)
                }

                Spacer()
            }
            .padding(.horizontal, 80)
        }
    }

    // MARK: - Actions

    private func login() async {
        print("LoginView → Sign In tapped for email: \(email)")

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await api.login(email: email, password: password)
            // EmberTVApp watches api.token and will switch to MyRentalsView on success.
        } catch {
            print("LoginView → login error: \(error)")
            errorMessage = "Sign-in failed. Please check your email and password."
        }

        isLoading = false
    }
}

// MARK: - Login button style

struct EmberLoginPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ButtonBody(configuration: configuration)
    }

    private struct ButtonBody: View {
        @Environment(\.isFocused) private var isFocused: Bool
        let configuration: Configuration

        var body: some View {
            configuration.label
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(EmberTheme.primary)
                )
                .foregroundColor(.white)
                .scaleEffect(isFocused || configuration.isPressed ? 1.06 : 1.0)
                .shadow(
                    color: isFocused ? EmberTheme.primary.opacity(0.7) : .clear,
                    radius: 18, x: 0, y: 0
                )
                .animation(.easeOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .focusEffectDisabled(true)
        }
    }
}

