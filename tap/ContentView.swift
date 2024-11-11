import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isAuthenticated = false
    @State private var userFirstName: String = UserDefaults.standard.string(forKey: "userFirstName") ?? "user"

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isAuthenticated {
                    DashboardView(firstName: $userFirstName, isAuthenticated: $isAuthenticated)
                } else {
                    if colorScheme == .dark {
                        Image("WhiteLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                    } else {
                        Image("BlackLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                    }

                    Text("tap into the future ᯤ")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    SignInWithAppleButton(
                        .signIn,
                        onRequest: configureRequest,
                        onCompletion: handleAuthorization
                    )
                    .frame(height: 44)
                    .padding(.horizontal, 20)
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .padding(.top, 20)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .onAppear {
                checkCredentialState()
            }
        }
    }

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                UserDefaults.standard.set(userID, forKey: "userID")

                if let fullName = appleIDCredential.fullName, let givenName = fullName.givenName {
                    userFirstName = givenName
                    UserDefaults.standard.set(givenName, forKey: "userFirstName")
                }
            }
            isAuthenticated = true
        case .failure(let error):
            print("authorization failed: \(error)")
            isAuthenticated = false
        }
    }

    private func checkCredentialState() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            isAuthenticated = false
            return
        }

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userID) { (credentialState, error) in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    isAuthenticated = true
                case .revoked, .notFound:
                    isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "userID")
                default:
                    break
                }
            }
        }
    }
}
