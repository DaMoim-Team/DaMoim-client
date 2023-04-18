//
//  settingsViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/18.
//

import UIKit
import FirebaseAuth

class settingsViewController: UIViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        do{
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
