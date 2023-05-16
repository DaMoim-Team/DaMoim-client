//
//  cleanViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/05/09.
//

import UIKit
import Foundation

class cleanViewController: UIViewController {
    
    @IBOutlet weak var Topic1: UISwitch!
    @IBOutlet weak var Topic2: UISwitch!
    @IBOutlet weak var Topic3: UISwitch!
    @IBOutlet weak var Topic4: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Topic1.isOn = false
        Topic2.isOn = false
        Topic3.isOn = false
        Topic4.isOn = false
    }
    
    @IBAction func AllSelect(_ sender: UIButton) {
        Topic1.isOn = true
        Topic2.isOn = true
        Topic3.isOn = true
        Topic4.isOn = true
    }
    
    @IBAction func CleanUpButton(_ sender: UIButton) {
        //선택된 토픽들 selectedTopics에 담기
        var selectedTopics: [String] = []
        
        if Topic1.isOn {
            selectedTopics.append("cctv_1")
        }
        if Topic2.isOn {
            selectedTopics.append("cctv_2")
        }
        if Topic3.isOn {
            selectedTopics.append("cctv_3")
        }
        if Topic4.isOn {
            selectedTopics.append("cctv_4")
        }
        print(selectedTopics)
        sendSelectedTopicsToServer(topics: selectedTopics)
    }
    
    //서버로 전송
    func sendSelectedTopicsToServer(topics: [String]){
        let url = URL(string: "http://52.79.138.34:1105/update_topics")
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let postBody = ["selectedTopics": topics]
            request.httpBody = try? JSONSerialization.data(withJSONObject: postBody)

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error:", error ?? "Unknown error")
                    return
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response string: \(responseString)")
                }
            }
            task.resume()
    }
}
