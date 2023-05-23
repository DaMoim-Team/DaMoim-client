//
//  graphViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/05/10.
//

import UIKit
import Charts

class graphViewController: UIViewController {
    
    var ranges : [String] = [] //"9h", "10h", "11h", "12h", "13h", "14h", "15h", "16h", "17h"
    var counts : [Int] = [] //6, 8, 26, 30, 8, 10, 7, 16, 27
    var specificValues : [String] = [] //cctv_id "1번", "2번", "3번", "4번", "5번", "6번", "7번", "8번", "9번"

    @IBOutlet weak var explainLabel: UILabel!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var topicText: UILabel!
    @IBOutlet weak var countText: UILabel!
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //JSON 가져오기
        fetchTimeranking().fetchTimerankingData() { timerankings, error in
            if let error = error {
                // error handling
                print("Failed to fetch data: ", error)
                return
            }

            guard let timerankings = timerankings else {
                // timerankings is nil
                print("No data received.")
                return
            }

            // 차트에 데이터 업데이트
            self.ranges = timerankings.map { $0.timeRange }
            self.counts = timerankings.map { $0.topCount }
            self.specificValues = timerankings.map { $0.most }
            
            // 데이터 확인
            print("Ranges: \(self.ranges)")
            print("Counts: \(self.counts)")
            print("Specific Values: \(self.specificValues)")


            // 차트 업데이트
            DispatchQueue.main.async {
                self.setChart(dataPoints: self.ranges, values: self.counts.map { Double($0) })
                self.updateUI()
            }
        }
        
        
        //애니메이션 코드(빼도됩니다.)
        barChartView.animate(yAxisDuration: 2.0)
        barChartView.pinchZoomEnabled = false
        barChartView.drawBarShadowEnabled = false
        barChartView.drawBordersEnabled = false
        barChartView.doubleTapToZoomEnabled = false
        barChartView.drawGridBackgroundEnabled = true
        barChartView.xAxis.setLabelCount(counts.count, force: false)
        barChartView.rightAxis.enabled = false
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ranges)
        barChartView.xAxis.labelFont = UIFont.systemFont(ofSize: 12)
        barChartView.xAxis.labelTextColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)
        barChartView.leftAxis.labelFont = UIFont.systemFont(ofSize: 12)
        barChartView.leftAxis.labelTextColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)
        barChartView.backgroundColor = .white
        barChartView.gridBackgroundColor = .systemGroupedBackground
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.drawGridLinesEnabled = false
        barChartView.rightAxis.drawGridLinesEnabled = false
        barChartView.legend.enabled = false

        
        //setChart(dataPoints: ranges, values: counts.map { Double($0) })
        
        // 1초마다 updateClock 함수를 호출하는 타이머 생성
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateClock), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    func updateUI() {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: date)

        if let hh = components.hour, hh >= 9, hh <= 17, specificValues.count > hh - 9, counts.count > hh - 9 {
            switch hh {
            case 9...17:
                topicText.text = specificValues[hh - 9]
                countText.text = ": 검출수 \(counts[hh - 9])회"
            default:
                topicText.text = " "
                countText.text = " "
                explainLabel.text = "검출 시간이 아닙니다"
            }
        }else {
            topicText.text = " "
            countText.text = " "
            explainLabel.text = "검출 시간이 아닙니다"
        }
    }
    
    func setChart(dataPoints: [String], values: [Double]) {
        barChartView.noDataText = "You need to provide data for the chart."

        var dataSets: [BarChartDataSet] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(values[i]), data: specificValues[i] as AnyObject)
            let chartDataSet = BarChartDataSet(entries: [dataEntry], label: "\(dataPoints[i])")
            
            // specific index you want to change color
            let date = Date()
            let calender = Calendar.current
            let components = calender.dateComponents([.hour], from: date)
            
            chartDataSet.colors = [UIColor(hex: 0xA8DAFF, alpha: 0.5)]
            if let hh = components.hour{
                if hh >= 9 && hh <= 17{
                    if i == hh - 9 {
                        chartDataSet.setColor(UIColor.systemBlue) // Set the color you want here
                    }
                }
            }
            
            chartDataSet.valueFormatter = MyValueFormatter(values: specificValues)
            chartDataSet.valueFont = UIFont.systemFont(ofSize: 10)
            chartDataSet.valueTextColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)
            
            dataSets.append(chartDataSet)
        }
        
        let chartData = BarChartData(dataSets: dataSets)
        barChartView.data = chartData
    }

    
    @objc func updateClock() {
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH시 mm분 ss초"
        
        let dateString = formatter.string(from: now)
        timeLabel.text = dateString
    }
}

class MyValueFormatter: ValueFormatter {
    let values: [String]

    init(values: [String]) {
        self.values = values
    }
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        return entry.data as? String ?? ""
    }

}

extension UIColor {
    convenience init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}
