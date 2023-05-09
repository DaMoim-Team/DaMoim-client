//
//  ViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/12.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore


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
            
            Firestore.firestore().collection("users").document(user.email ?? "No Email").getDocument { (document, error) in
                if let error = error {
                    print("Error getting user data: \(error)")
                } else {
                    if let document = document, document.exists {
                        if let jobNum = document.get("job") as? Int {
                            if jobNum == 0 {
                                self.navigateToSecondNavigationController()
                            } else if jobNum == 1 {
                                self.navigateToThirdNavigationController()
                            }
                        }
                    }
                }
            }
            
//            guard let secondNavController = self.storyboard?.instantiateViewController(withIdentifier: "secondNavControllerID") as? UINavigationController else { return }
//            navigateToSecondNavigationController()
            //navigateToTabBarController()
            
            
//            let transition = CATransition()
//            transition.duration = 0.5
//            transition.type = CATransitionType.push
//            transition.subtype = CATransitionSubtype.fromRight
//            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//
//            if let window = view.window {
//                window.layer.add(transition, forKey: kCATransition)
//                window.rootViewController = secondNavController
//                window.makeKeyAndVisible()
//            }
            //self.present(whereToGoViewController, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func loginAction(_ sender: Any) {
        
        let email: String = emailTextField.text!.description
        let password: String = passwordTextField.text!.description
        
        guard let whereToGoViewController = self.storyboard?.instantiateViewController(withIdentifier: "whereToGoViewControllerID") as? whereToGoViewController else { return }
        whereToGoViewController.modalTransitionStyle = .coverVertical
        whereToGoViewController.modalPresentationStyle = .fullScreen
        
        
        Auth.auth().signIn(withEmail: email, password: password) {authResult, error in
            if let e = error {
                print(e)
            }
            
            if authResult != nil{
                print("로그인성공")
                if let user = Auth.auth().currentUser{
                    Firestore.firestore().collection("users").document(user.email ?? "No Email").getDocument { (document, error) in
                        if let error = error {
                            print("Error getting user data: \(error)")
                        } else {
                            if let document = document, document.exists {
                                if let jobNum = document.get("job") as? Int {
                                    if jobNum == 0 {
                                        self.navigateToSecondNavigationController()
                                    } else if jobNum == 1 {
                                        self.navigateToThirdNavigationController()
                                    }
                                }
                            }
                        }
                    }
                }
                //self.navigateToSecondNavigationController()
                //self.navigateToTabBarController()
                //self.present(whereToGoViewController, animated: true, completion: nil)
                
            } else{
                print("로그인실패")
                print(error.debugDescription)
                
                let alertController = UIAlertController(title: "로그인 실패", message: "이메일, 비밀번호를 확인해주세요.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "확인", style: .default, handler: { [weak self] action in
                    // 클로저 내에서 self를 weak 또는 unowned로 캡처하여 강한 참조 순환 참조 방지
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
            
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromRight
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

            if let window = view.window {
                window.layer.add(transition, forKey: kCATransition)
                window.rootViewController = secondNavController
                window.makeKeyAndVisible()
            }
            
            self.present(secondNavController, animated: true, completion: nil)
        }
    }
    
    func navigateToThirdNavigationController() {
        if let thirdNavController = self.storyboard?.instantiateViewController(withIdentifier: "thirdNavControllerID") as? UINavigationController {
            thirdNavController.modalPresentationStyle = .fullScreen
            
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromRight
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

            if let window = view.window {
                window.layer.add(transition, forKey: kCATransition)
                window.rootViewController = thirdNavController
                window.makeKeyAndVisible()
            }
            
            self.present(thirdNavController, animated: true, completion: nil)
        }
    }

    
    func navigateToTabBarController() {//탭바 전환용
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // "Main"은 스토리보드의 이름입니다.
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            // 애니메이션과 함께 뷰 컨트롤러 전환 (옵션)
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromRight
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            if let window = view.window {
                window.layer.add(transition, forKey: kCATransition)
                window.rootViewController = tabBarController
                window.makeKeyAndVisible()
            }
        }
    }

    

}

