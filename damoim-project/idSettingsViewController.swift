//
//  idSettingsViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/18.
//

import UIKit
import Firebase
import FirebaseAuth

class idSettingsViewController: UIViewController {
    
    
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var emailText: UILabel!
    
    
    @IBOutlet weak var jobControl: UISegmentedControl!
    
    @IBOutlet weak var changeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        if let user = Auth.auth().currentUser {
            let userEmail = user.email ?? "No Email"
            
            Firestore.firestore().collection("users").document(userEmail).getDocument{ (document, error) in
                if let error = error{
                    print("Error getting user data \(error)")
                } else{
                    if let document = document, document.exists{
                        let userName = document.get("name") as? String ?? "No Name"
                        if let jobNum = document.get("job") as? Int{
                            self.jobControl.selectedSegmentIndex = jobNum
                        }
                        self.nameText.text = userName + " 님"
                        self.emailText.text = userEmail
                        self.changeButton.isEnabled = true
                    }
                }
            }
        } else {
            nameText.text = "No User"
            emailText.text = "No User"
        }
        
    }
    
    @IBAction func changeButtonAction(_ sender: UIButton) {
        if let user = Auth.auth().currentUser {
            let userEmail = user.email ?? "No Email"
            let selectedJobIndex = jobControl.selectedSegmentIndex
            
            Firestore.firestore().collection("users").document(userEmail).updateData([
                "job": selectedJobIndex
            ]) { error in
                if let error = error {
                    print("Error updating user data: \(error)")
                } else {
                    print("User data successfully updated")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
}
