//
//  graphViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/05/10.
//

import UIKit
import Charts

class graphViewController: UIViewController {
    
    let ranges = ["9h", "10h", "11h", "12h", "13h", "14h", "15h", "16h", "17h"]
    let counts = [6, 8, 26, 30, 8, 10, 7, 16, 27]
    let specificValues = ["1번", "2번", "3번", "4번", "5번", "6번", "7번", "8번", "9번"]
    

    @IBOutlet weak var explainLabel: UILabel!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var topicText: UILabel!
    @IBOutlet weak var countText: UILabel!
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        barChartView.gridBackgroundColor = .clear
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.drawGridLinesEnabled = false
        barChartView.rightAxis.drawGridLinesEnabled = false
        barChartView.legend.enabled = false


        
        setChart(dataPoints: ranges, values: counts.map { Double($0) })
        
        // 1초마다 updateClock 함수를 호출하는 타이머 생성
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateClock), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.hour], from: date)
        
        if let hh = components.hour{
            switch hh{
            case 9:
                topicText.text = specificValues[0]
                countText.text = ": 검출수 \(counts[0])회"
            case 10:
                topicText.text = specificValues[1]
                countText.text = ": 검출수 \(counts[1])회"
            case 11:
                topicText.text = specificValues[2]
                countText.text = ": 검출수 \(counts[2])회"
            case 12:
                topicText.text = specificValues[3]
                countText.text = ": 검출수 \(counts[3])회"
            case 13:
                topicText.text = specificValues[4]
                countText.text = ": 검출수 \(counts[4])회"
            case 14:
                topicText.text = specificValues[5]
                countText.text = ": 검출수 \(counts[5])회"
            case 15:
                topicText.text = specificValues[6]
                countText.text = ": 검출수 \(counts[6])회"
            case 16:
                topicText.text = specificValues[7]
                countText.text = ": 검출수 \(counts[7])회"
            case 17:
                topicText.text = specificValues[8]
                countText.text = ": 검출수 \(counts[8])회"
            case 18:
                topicText.text = specificValues[9]
                countText.text = ": 검출수 \(counts[9])회"
            default:
                topicText.text = " "
                countText.text = " "
                explainLabel.text = "검출 시간이 아닙니다"
            }
        }
    }
    
    func setChart(dataPoints: [String], values: [Double]) {
        barChartView.noDataText = "You need to provide data for the chart."

        var dataEntries: [BarChartDataEntry] = []

        for i in 0..<dataPoints.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(values[i]), data: specificValues[i] as AnyObject)
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries, label: "Bar Chart View")
        chartDataSet.valueFormatter = MyValueFormatter(values: specificValues)
        chartDataSet.valueFont = UIFont.systemFont(ofSize: 12)
        chartDataSet.valueTextColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)

        let chartData = BarChartData(dataSet: chartDataSet)
        barChartView.data = chartData
    }
    
    @objc func updateClock() {
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
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




//class graphViewController: UIViewController {
//
//    let players = ["Ozil", "Ramsey", "Laca", "Auba", "Xhaka", "Torreira"]
//    let goals = [6, 8, 26, 30, 8, 10]
//    let specificValues = ["topic_1", "topic_2", "topic_3", "topic_4", "topic_5", "topic_6"]
//
//    //@IBOutlet weak var lineChartView: LineChartView!
//    @IBOutlet weak var barChartView: LineChartView! //BarChartView
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        barChartView.animate(yAxisDuration: 2.0)
//        barChartView.pinchZoomEnabled = false
//        barChartView.doubleTapToZoomEnabled = false
//        barChartView.chartDescription.text = "Line Chart View"
//
//        setChart(dataPoints: players, values: goals.map { Double($0) })
//        marker.chartView = barChartView
//        barChartView.marker = marker
//    }
//
//    func setChart(dataPoints: [String], values: [Double]) {
//        barChartView.noDataText = "You need to provide data for the chart."
//
//        var dataEntries: [ChartDataEntry] = []
//
//        for i in 0..<dataPoints.count {
//            let dataEntry = ChartDataEntry(x: Double(i), y: values[i])
//            dataEntries.append(dataEntry)
//        }
//
//        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "Line Chart View")
//        chartDataSet.valueFormatter = DefaultValueFormatter { (value, entry, index, viewPortHandler) -> String in
//            return self.specificValues[index]
//        }
//
//        chartDataSet.drawValuesEnabled = true
//
//        let chartData = LineChartData(dataSet: chartDataSet)
//        barChartView.data = chartData
//    }
//
//}
    
    
    
    
    
    

