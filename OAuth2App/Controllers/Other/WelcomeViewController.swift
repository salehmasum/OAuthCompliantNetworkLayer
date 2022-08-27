//
//  WelcomeViewController.swift
//  OAuth2App
//
//  Created by Saleh Masum on 26/8/2022.
//

import UIKit

class WelcomeViewController: UIViewController {

    private let signInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.setTitle("Sign In With Spotify", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(signInButton)
        signInButton.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
    }
    
    @objc func signInButtonTapped() {
        print("button pressed")
        let authVc = AuthViewController()
        authVc.completionHandler = { [weak self] success in
            self?.handleSignIn(success: success)
        }
        authVc.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(authVc, animated: true)
    }
    
    private func handleSignIn(success: Bool) {
        //Log user in or handle error
        guard success else {
            let alert = UIAlertController(title: "Error", message: "Sign In Attempt Failed", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alert, animated: true)
            return
        }
        let mainTabbarController = MainTabBarController()
        mainTabbarController.modalPresentationStyle = .fullScreen
        present(mainTabbarController, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        signInButton.frame = CGRect(
            x: 20,
            y: view.height - 100 - view.safeAreaInsets.bottom,
            width: view.width - 40,
            height: 50
        )
    }

}
