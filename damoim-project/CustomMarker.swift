//
//  CustomMarker.swift
//  damoim-project
//
//  Created by hansung on 2023/05/10.
//

import Foundation
import UIKit

class CustomMarker: MarkerView {
    var text = ""

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        super.refreshContent(entry: entry, highlight: highlight)
        // set the entry.x to find the correct value from the specificValues array
        if let index = Int(entry.x) {
            text = specificValues[index]
        }
    }

    override func draw(context: CGContext, point: CGPoint) {
        super.draw(context: context, point: point)
        // customise your drawing code to show the label
        // for example:
        UIGraphicsPushContext(context)
        context.drawText(text, at: CGPoint(x: 0, y: 0), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black])
        UIGraphicsPopContext()
    }
}

