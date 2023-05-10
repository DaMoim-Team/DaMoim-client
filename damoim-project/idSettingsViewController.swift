//
//  idSettingsViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/18.
//
// 안쓰는코드. 나중에 삭제.


import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class idSettingsViewController: UIViewController {
    
    
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var emailText: UILabel!
    
    @IBOutlet weak var jobText: UILabel!
    
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
                        let jobNum = document.get("job") as? Int
                        self.nameText.text = userName + " 님"
                        if jobNum == 0{
                            self.jobText.text = "직업 : 학교청소미화원"
                        }
                        else if jobNum == 1{
                            self.jobText.text = "직업 : 금연구역단속반"
                        }
                        self.emailText.text = userEmail
                    }
                }
            }
        } else {
            nameText.text = "No User"
            emailText.text = "No User"
        }
        
    }
    
//    @IBAction func changeButtonAction(_ sender: UIButton) {
//        if let user = Auth.auth().currentUser {
//            let userEmail = user.email ?? "No Email"
//            let selectedJobIndex = jobControl.selectedSegmentIndex
//
//            Firestore.firestore().collection("users").document(userEmail).updateData([
//                "job": selectedJobIndex
//            ]) { error in
//                if let error = error {
//                    print("Error updating user data: \(error)")
//                } else {
//                    print("User data successfully updated")
//                    self.navigationController?.popViewController(animated: true)
//                }
//            }
//        }
//    }
    
}
