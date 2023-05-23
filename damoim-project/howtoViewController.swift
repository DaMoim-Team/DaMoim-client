//
//  howtoViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/18.
//

import UIKit

class howtoViewController: UIViewController {
    
    var helpText: String?
    var helpLabel: UILabel! // 레이블을 먼저 선언합니다.
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 레이블 초기화
        helpLabel = UILabel(frame: view.bounds) // 여기서 뷰의 경계를 사용합니다.
        helpLabel.text = helpText // helpText를 사용
        helpLabel.numberOfLines = 0 // 여러 줄의 텍스트를 허용
        helpLabel.textAlignment = .center // 텍스트를 가운데 정렬
        helpLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight] // 뷰 크기 변경에 따라 레이블 크기 조절
        helpLabel.font = UIFont.systemFont(ofSize: 18) // 폰트 크기 설정
        helpLabel.lineBreakMode = .byWordWrapping // 단어를 기준으로 줄바꿈

        // 레이블을 뷰에 추가
        view.addSubview(helpLabel)
    }
}
