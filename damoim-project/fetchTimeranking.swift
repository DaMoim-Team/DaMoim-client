//
//  fetchTimeranking.swift
//  damoim-project
//
//  Created by hansung on 2023/05/17.
//

import Foundation
import CoreLocation

//timeranking 데이터 구조체 정의
struct TimerankingResponse: Decodable {
    let timerankingData: [Timeranking]
    
    enum CodingKeys: String, CodingKey {
        case timerankingData = "timeranking_data"
    }
}

struct Timeranking: Decodable {
    let timeRange: String
    let most: String
    let topCount: Int
    
    enum CodingKeys: String, CodingKey {
        case timeRange = "time_range"
        case most
        case topCount = "top_count"
    }
}

//서버에서 JSON 파일을 가져옴
class fetchTimeranking {
    //timeranking
    func fetchTimerankingData(completion: @escaping ([Timeranking]?, Error?) -> Void) {
        guard let url = URL(string: "http://52.79.138.34:1105/timeranking") else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Data Task Error: \(error)")
                return
            }
            guard let data = data else {
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data is nil"]))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let timerankingResponse = try decoder.decode(TimerankingResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(timerankingResponse.timerankingData, nil)
                }
                
            } catch {
                print("Decoding Error: \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
}
