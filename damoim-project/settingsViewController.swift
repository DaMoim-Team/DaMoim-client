//
//  settingsViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/18.
//
// 안쓰는코드. 나중에 삭제.

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
        navigateToLoginViewController()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func idsettingAction(_ sender: Any) {
        guard let idSettingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "idSettingsViewControllerID") as? idSettingsViewController else{
            return
        }
        self.navigationController?.pushViewController(idSettingsViewController, animated: true)
    }
    
    
    @IBAction func howtoAction(_ sender: Any) {
        guard let howtoViewController = self.storyboard?.instantiateViewController(withIdentifier: "howtoViewControllerID") as? howtoViewController else{
            return
        }
        self.navigationController?.pushViewController(howtoViewController, animated: true)
    }
    
    
    func navigateToLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // "Main"은 스토리보드의 이름입니다.
        if let navigationController = storyboard.instantiateViewController(withIdentifier: "firstNavControllerID") as? UINavigationController,
           let loginViewController = navigationController.viewControllers.first as? loginViewController {
            // 애니메이션과 함께 뷰 컨트롤러 전환 (옵션)
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            view.window!.layer.add(transition, forKey: kCATransition)

            // 로그인 뷰 컨트롤러를 새로운 루트 뷰 컨트롤러로 설정합니다.
            view.window?.rootViewController = navigationController
            view.window?.makeKeyAndVisible()
        }
    }

}
