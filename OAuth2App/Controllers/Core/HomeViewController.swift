//
//  HomeViewController.swift
//  OAuth2App
//
//  Created by Saleh Masum on 27/8/2022.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        showSuccessDialogue()
    }
    
    private func showSuccessDialogue() {
        let alert = UIAlertController(title: "Success", message: "Successfully signed in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }

}
