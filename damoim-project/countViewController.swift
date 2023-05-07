//
//  countViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/05/07.
//

import UIKit
import Foundation

class countViewController: UIViewController{
    var slider: UISlider!
    var minCount: Int = 3//기본값 3
    weak var delegate: CountViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        minCount = UserDefaults.standard.integer(forKey: "minCount") == 0 ? 3 : UserDefaults.standard.integer(forKey: "minCount")
        
        // 슬라이더 생성 및 초기 설정
        slider = UISlider(frame: CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 40))
        slider.minimumValue = 1
        slider.maximumValue = 10
        slider.value = Float(minCount)
        slider.isContinuous = true
        
        // 값 변경 시 호출될 함수 설정
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        view.addSubview(slider)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let whereToGoVC = navigationController?.viewControllers.first as? whereToGoViewController {
            whereToGoVC.minCount = Int(slider.value)
        }
        UserDefaults.standard.set(minCount, forKey: "minCount")
        
        self.minCount = Int(slider.value)
    }

    
    // 슬라이더 값 변경 시 호출되는 함수
    @objc func sliderValueChanged(_ sender: UISlider) {
        minCount = Int(sender.value)
        delegate?.updateMinimumCount(minCount)
        print("New minimumCount value: \(minCount)")
    }

}
