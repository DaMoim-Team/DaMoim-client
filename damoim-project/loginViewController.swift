//
//  ViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/12.
//

import UIKit
import FirebaseAuth


class loginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let user = Auth.auth().currentUser{
            guard let mainViewController = self.storyboard?.instantiateViewController(identifier: "mainViewControllerID") as? mainViewController else { return }
            navigateToSecondNavigationController()
            self.present(mainViewController, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func loginAction(_ sender: Any) {
        
        let email: String = emailTextField.text!.description
        let password: String = passwordTextField.text!.description
        
        guard let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "mainViewControllerID") as? mainViewController else { return }
        mainViewController.modalTransitionStyle = .coverVertical
        mainViewController.modalPresentationStyle = .fullScreen
        
        
        Auth.auth().signIn(withEmail: email, password: password) {authResult, error in
            if let e = error {
                print(e)
            }
            
            if authResult != nil{
                print("로그인성공")
                self.navigateToSecondNavigationController()
                self.present(mainViewController, animated: true, completion: nil)
                
            } else{
                print("로그인실패")
                print(error.debugDescription)
                
                let alertController = UIAlertController(title: "로그인 실패", message: "이메일, 비밀번호를 확인해주세요.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "확인", style: .default, handler: { [weak self] action in
                    // 클로저 내에서 self를 weak 또는 unowned로 캡처하여 강한 참조 순환 참조 방지kkk
                    guard let self = self else { return }
                })
                alertController.addAction(okAction)

                self.present(alertController, animated: true, completion: nil)

            }
        }
        
        
    }
    
    @IBAction func registerAction(_ sender: Any) {
        
        let registerViewController = self.storyboard?.instantiateViewController(withIdentifier: "registerViewControllerID")
        self.navigationController?.pushViewController(registerViewController!, animated: true)
        
    }
    
    func navigateToSecondNavigationController() {
        if let secondNavController = self.storyboard?.instantiateViewController(withIdentifier: "secondNavControllerID") as? UINavigationController {
            secondNavController.modalPresentationStyle = .fullScreen
            self.present(secondNavController, animated: true, completion: nil)
        }
    }
    
    

}

