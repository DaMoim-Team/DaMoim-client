//
//  countViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/05/07.
//

import UIKit
import Foundation

class countViewController: UIViewController{
    var titleLabel: UILabel!
    var explainLabel: UILabel!
    var slider: UISlider!
    var countLabel: UILabel!
    var minCount: Int = 3//기본값 3
    weak var delegate: CountViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        minCount = UserDefaults.standard.integer(forKey: "minCount") == 0 ? 3 : UserDefaults.standard.integer(forKey: "minCount")
        
        // "경로추천설정" 레이블 생성
        titleLabel = UILabel()
        titleLabel.text = "경로추천설정"
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 25)

        
        // 설명레이블
        explainLabel = UILabel()
        explainLabel.text = "경로설정을 할 때 최소 검출 수를 조정할 수 있습니다. \n설정한 수 미만의 장소는 경로설정에서 제외됩니다."
        explainLabel.textColor = .black
        explainLabel.translatesAutoresizingMaskIntoConstraints = false
        explainLabel.font = UIFont.systemFont(ofSize: 15)
        explainLabel.numberOfLines = 0

        
        // 슬라이더 생성 및 초기 설정
        slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 1
        slider.maximumValue = 10
        slider.value = Float(minCount)
        slider.isContinuous = true

        
        // 슬라이더 옆에 표시할 count 값 레이블 생성
        countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.text = "\(minCount)"
        countLabel.font = UIFont.systemFont(ofSize: 18)
        
        // 값 변경 시 호출될 함수 설정
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        // 뷰에 레이블과 슬라이더 추가
        view.addSubview(titleLabel)
        view.addSubview(explainLabel)
        view.addSubview(slider)
        view.addSubview(countLabel)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            explainLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            explainLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            slider.topAnchor.constraint(equalTo: explainLabel.bottomAnchor, constant: 20),
            slider.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -40),
            countLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            countLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 20)
        ])

    }
    
    // 뷰가 꺼지고
    // if let 부분에서 값이 전달 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let whereToGoVC = navigationController?.viewControllers.first as? whereToGoViewController {
            whereToGoVC.minCount = Int(slider.value)
        }
        if let catchVC = navigationController?.viewControllers.first as? catchViewController {
            catchVC.minCount = Int(slider.value)
        }
        UserDefaults.standard.set(minCount, forKey: "minCount")
        
        self.minCount = Int(slider.value)
    }

    // 슬라이더 값 변경 시 호출되는 함수
    @objc func sliderValueChanged(_ sender: UISlider) {
        minCount = Int(sender.value)
        self.countLabel.text = "\(minCount)"
        delegate?.updateMinimumCount(minCount)
        print("New minimumCount value: \(minCount)")
    }
}
