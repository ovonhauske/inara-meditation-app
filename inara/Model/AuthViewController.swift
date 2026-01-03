import UIKit
import AuthenticationServices

class AuthViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSignInButton()
    }
    
    func setupSignInButton() {
        let button = ASAuthorizationAppleIDButton()
        button.center = view.center
        view.addSubview(button)
        button.addTarget(self, action: #selector(handleSignInPress), for: .touchUpInside)
    }
    
    @objc func handleSignInPress() {
        performSegue(withIdentifier: "kAuthToContactsSegueId",
                     sender: nil)
    }
}


