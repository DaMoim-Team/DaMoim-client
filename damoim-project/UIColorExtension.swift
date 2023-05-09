//
//  UIColorExtension.swift
//  damoim-project
//
//  Created by hansung on 2023/05/09.
//

import UIKit

extension UIColor {
    static func interpolate(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        let fromComponents = from.cgColor.components!
        let toComponents = to.cgColor.components!
        let r = (toComponents[0] - fromComponents[0]) * progress + fromComponents[0]
        let g = (toComponents[1] - fromComponents[1]) * progress + fromComponents[1]
        let b = (toComponents[2] - fromComponents[2]) * progress + fromComponents[2]
        let a = (toComponents[3] - fromComponents[3]) * progress + fromComponents[3]
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

