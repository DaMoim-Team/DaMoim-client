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
            navigateToTabBarController()
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
                self.navigateToTabBarController()
                self.present(mainViewController, animated: true, completion: nil)
                
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
        }
    }
    
    func navigateToTabBarController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // "Main"은 스토리보드의 이름입니다.
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            // 애니메이션과 함께 뷰 컨트롤러 전환 (옵션)
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromRight
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            view.window!.layer.add(transition, forKey: kCATransition)

            // 탭바 컨트롤러를 새로운 루트 뷰 컨트롤러로 설정합니다.
            view.window?.rootViewController = tabBarController
            view.window?.makeKeyAndVisible()
        }
    }

    

}

