//
//  Config.swift
//  damoim-project
//
//  Created by hansung on 2023/05/23.
//

import Foundation

struct Config {
    static var NMFClientId: String?
    static var NMFClientSecret: String?
    static var DirectionAPI: String?
    static var clientIdKey: String?
    static var clientSecretKey: String?

    static func load() {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let nsDictionary = NSDictionary(contentsOfFile: path)
            NMFClientId = nsDictionary?.object(forKey: "NMFClientId") as? String
            NMFClientSecret = nsDictionary?.object(forKey: "NMFClientSecret") as? String
            DirectionAPI = nsDictionary?.object(forKey: "DirectionAPI") as? String
            clientIdKey = nsDictionary?.object(forKey: "clientIdKey") as? String
            clientSecretKey = nsDictionary?.object(forKey: "clientSecretKey") as? String
        }
    }
}
