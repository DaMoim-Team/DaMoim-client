//
//  registerViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/13.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class registerViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repwTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var whoAmI: UISegmentedControl!
    
    @IBOutlet weak var idIsInvalid: UILabel!
    @IBOutlet weak var pwIsInvalid: UILabel!
    @IBOutlet weak var pwIsNotCorrect: UILabel!
    @IBOutlet weak var nameIsInvalid: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        
        idIsInvalid.isHidden = true
        pwIsNotCorrect.isHidden = true
        pwIsInvalid.isHidden = true
        nameIsInvalid.isHidden = true
        
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let repassword = repwTextField.text, !repassword.isEmpty,
              let name = nameTextField.text, !name.isEmpty else{
            print("모든 항목을 입력하세요.")
            let alertController = UIAlertController(title: "오류", message: "모든 항목을 입력하세요.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default, handler: { action in
                
            })
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
            return
        }
        
        if isValidEmail(email) {
            print("이메일형식 맞음")
        } else {
            print("이메일형식이 아님")
            idIsInvalid.isHidden = false
            return
        }
        
        if password.count < 6 {
            print("비밀번호 글자수 적음")
            pwIsInvalid.isHidden = false
            return
        }
        
        if password != repassword {
            print("비밀번호 재확인 실패")
            pwIsNotCorrect.isHidden = false
            return
        }
        
        if name.count > 7 {
            print("너무 긴 이름")
            nameIsInvalid.isHidden = false
            return
        }
        
        if name.count < 2 {
            print("너무 짧은 이름")
            nameIsInvalid.isHidden = false
            return
        }
        
        if whoAmI.selectedSegmentIndex == 0{
            print("미화원")
        }else{
            print("단속반")
        }
        
        Auth.auth().createUser(withEmail: email, password: password){ (result, error) in
            if let error = error {
                print("회원가입 실패")
                
            } else{
                print("회원가입 성공")
                Firestore.firestore().collection("users").document(email).setData(["name": name , "email": email , "job": self.whoAmI.selectedSegmentIndex])
                self.navigationController?.popViewController(animated: true)
            }
            
        }
        
    }
    
    
}
