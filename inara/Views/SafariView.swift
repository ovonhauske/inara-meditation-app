import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredBarTintColor = UIColor(AppColors.surface)
        vc.preferredControlTintColor = UIColor(AppColors.tulum)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // no-op
    }
}
