import SwiftUI
import SafariServices

struct PaymentsView: View {
    @State private var showSafari = false
    @State private var stripeURL: URL? = URL(string: "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=ca_QykMeOj0UeomGnrQ2beQz0Au6Ygfj2pH&scope=read_write")

    var body: some View {
        VStack {
            if let validURL = stripeURL {
                Button("Connect with Stripe") {
                    showSafari = true
                }
            } else {
                Text("Failed to load Stripe URL")
                    .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showSafari) {
            if let validStripeURL = stripeURL {
                SafariView(url: validStripeURL)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
