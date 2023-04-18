//
//  MainViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/13.
//

import UIKit
import FirebaseAuth

class mainViewController: UIViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func settingAction(_ sender: Any) {
        
        guard let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "settingsViewControllerID") as? settingsViewController else{
            return
        }
        self.navigationController?.pushViewController(settingsViewController, animated: true)
        
    }
    
    
    
}
