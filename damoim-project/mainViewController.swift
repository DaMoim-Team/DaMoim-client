//
//  MainViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/13.
//

import UIKit
import FirebaseAuth
import WebKit
import CoreLocation

class mainViewController: UIViewController {
    
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let urlStr = "https://damoim.shop"
        if let url = URL(string: urlStr){
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    
    @IBAction func settingAction(_ sender: Any) {
        guard let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "settingsViewControllerID") as? settingsViewController else{
            return
        }
        self.navigationController?.pushViewController(settingsViewController, animated: true)
        
    }
    
    
    
}
