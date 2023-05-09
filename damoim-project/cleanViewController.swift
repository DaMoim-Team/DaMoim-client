//
//  cleanViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/05/09.
//

import UIKit

class cleanViewController: UIViewController {
    
    @IBOutlet weak var Topic1: UISwitch!
    @IBOutlet weak var Topic2: UISwitch!
    @IBOutlet weak var Topic3: UISwitch!
    @IBOutlet weak var Topic4: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Topic1.isOn = false
        Topic2.isOn = false
        Topic3.isOn = false
        Topic4.isOn = false
    }
    
    @IBAction func AllSelect(_ sender: UIButton) {
        Topic1.isOn = true
        Topic2.isOn = true
        Topic3.isOn = true
        Topic4.isOn = true
    }
    
    
    @IBAction func CleanUpButton(_ sender: UIButton) {
        
    }
}
