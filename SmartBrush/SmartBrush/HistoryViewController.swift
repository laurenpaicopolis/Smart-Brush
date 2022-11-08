import UIKit
import Charts
import DropDown
 
class HistoryViewController: UIViewController {
    
    // Pointer to database
    var db: SQLiteDatabase?
    
    // Variables
    var buttonDecided = ""
    var countMonths = 11
    var countYears = 2
    var countWeeks = 0
    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    let weeks = ["Week One","Week Two","Week Three","Week Four","Week Five"]
    let years = ["2019","2020","2021"]
    @IBOutlet weak var lineChartView: LineChartView!
    var totalDaysInTimePeriod = 0
    var startIndex = 0
    
    // labels for user
    @IBOutlet weak var yearButtonVar: UIButton!
    @IBOutlet weak var weekButtonVar: UIButton!
    @IBOutlet weak var monthButtonVar: UIButton!
    @IBOutlet weak var monthDropdownButton: UIButton!
    @IBOutlet weak var arrowBackward: UIButton!
    @IBOutlet weak var arrowForward: UIButton!
    @IBOutlet var dateLabel: UILabel!
   
    
    // Queries data from database
    func queryData(type: String) -> Array<Double>? {
        
        // Variables
        var averages: [ToothBrushData] = []
        let currentYear = years[countYears]
        let year = Int(currentYear) ?? 0
        let month = countMonths + 1
        var finalAverages: [Double] = []
        
        // Year button clicked
        if type == "Year" {
            
            // Get all values from corresponding year
            guard let valuesYear = db?.data(Year: Int32(year)) else {
                return nil
            }
            
            // If no values from year fetched, return 0
            if valuesYear.count == 0 {
                return nil
            }
            averages = valuesYear
            totalDaysInTimePeriod = 12 // 12 months in one year
        }
        
        // Month or Week View
        else {
            
            // Get Month from current Year
            guard let currentMonthData = db?.data(Month: Int32(month), Year: Int32(year)) else {
                return nil
            }
            
            // Nothing fetched, return nil
            if currentMonthData.count == 0 {
                return nil
            }
            
            averages = currentMonthData
            
            // Total number of days in Month selected
            totalDaysInTimePeriod = Int(currentMonthData[0].numberOfDaysInMonth)
            
        }
        
        // Prepare finalAverages array for averages for entire month
        for _ in 1...totalDaysInTimePeriod {
            finalAverages.append(0.0)
        }
        
        // Calculates averages for each month/year
        for value in 1...totalDaysInTimePeriod {
            var count = 0.0
            
            // average in averages list
            for average in averages {
                
                // Month/Week with multiple values on same day
                if (type == "Month" || type == "Week") && average.day == value {
                    finalAverages[value - 1] += average.average
                    count += 1
                }
                // Year with multiple values in same month
                if type == "Year" && average.month == value {
                    finalAverages[value - 1] += average.average
                    count += 1
                }
            }
            
            // If there was more than one value in month or year, calculate total average
            if count > 0 {
                let total = finalAverages[value - 1]
                let totalAverage = total / count
                finalAverages[value - 1] = totalAverage
            }
        }
            
        // Week type
        if (type == "Week") {
            
            // calculates the first day of week to show
            startIndex = countWeeks * 7
            if startIndex != 0 {
                startIndex = startIndex - 1
            }
            
            // If its the last week, get the final averaged values from the month selected (days 29-31)
            // and display them in week 5 view
            if (countWeeks == 4)  {
                finalAverages = Array(finalAverages[startIndex...])
                
                // Append zero values to array for all other days in week not in current month selected
                let daysLeftToAdd = totalDaysInTimePeriod - startIndex
                let daysToMakeOneWeek = 7 - daysLeftToAdd
                for _ in 1...daysToMakeOneWeek {
                    finalAverages.append(0.0)
                }
            }
            
            // Weeks 1,2,3,4
            else {
                // Get 7 days of each week
                finalAverages = Array(finalAverages[startIndex...startIndex + 6])
            }
        }
    return finalAverages
    }
    
    // regulates what month/week/year user is clicking backward to
    @IBAction func arrowBackAction(_ sender: UIButton) {
       
        if (buttonDecided == "Month") {
            countMonths -= 1
            if (countMonths < 0) {
                countMonths = 11
                countYears -= 1
                if (countYears < 0) {
                    countYears = 2
                }
            }
            monthDropdownButton.setTitle(months[countMonths], for: .normal)
            let averagesMonth = queryData(type: "Month") ?? [0]
            print(averagesMonth)
            setLineChart("Month", Array:  averagesMonth)
            
            // update label with current month
            dateLabel.text = "\(months[countMonths]) \(years[countYears])"
        }
        
        if (buttonDecided == "Week") {
            countWeeks -= 1
            if (countWeeks < 0) {
                countWeeks = 4
                countMonths -= 1
                if (countMonths < 0) {
                    countMonths = 11
                    countYears -= 1
                    if (countYears < 0) {
                        countYears = 2
                    }
                }
            }
            
            monthDropdownButton.setTitle(weeks[countWeeks], for: .normal)
            let averagesWeek = queryData(type: "Week") ?? [0]
            setLineChart("Week", Array: averagesWeek)
            
            // update label with current month
            dateLabel.text = "\(months[countMonths]) \(years[countYears])"
        }
        if (buttonDecided == "Year") {
            countYears -= 1
            if (countYears < 0) {
                countYears = 2
                countMonths = 0
                countWeeks = 0
            }
            monthDropdownButton.setTitle(years[countYears], for: .normal)
            let averagesYear = queryData(type: "Year") ?? [0]
            print(averagesYear)
            setLineChart("Year", Array: averagesYear)
            
            // update label with current month
            dateLabel.text = "\(years[countYears])"
        }
    }

    // regulates what month/week/year user is clicking forward to
    @IBAction func arrowForwardAction(_ sender: UIButton) {
        if (buttonDecided == "Month") {
            countMonths += 1
            if (countMonths > 11) {
                countMonths = 0
                countYears += 1
                if (countYears > 2) {
                    countYears = 0
                }
            }
            monthDropdownButton.setTitle(months[countMonths], for: .normal)
            let averagesMonth = queryData(type: "Month") ?? [0]
            setLineChart("Month", Array:  averagesMonth)
            
            // update label with current month
            dateLabel.text = "\(months[countMonths]) \(years[countYears])"
        }
        
        if (buttonDecided == "Week") {
            countWeeks += 1
            if (countWeeks > 4) {
                countWeeks = 0
                countMonths += 1
                if (countMonths > 11) {
                    countMonths = 0
                    countYears += 1
                    if (countYears > 2) {
                        countYears = 0
                    }
                }
            }
            monthDropdownButton.setTitle(weeks[countWeeks], for: .normal)
            let averagesWeek = queryData(type: "Week") ?? [0]
            setLineChart("Week", Array: averagesWeek)
            
            // update label with current month
            dateLabel.text = "\(months[countMonths]) \(years[countYears])"
        }
        if (buttonDecided == "Year") {
            countYears += 1
            if (countYears > 2) {
                countYears = 0
                countMonths = 0
                countWeeks = 0
            }
            monthDropdownButton.setTitle(years[countYears], for: .normal)
            let averagesYear = queryData(type: "Year") ?? [0]
            setLineChart("Year", Array: averagesYear)
            
            // update label with current month
            dateLabel.text = "\(years[countYears])"
        }
        
    }
   
    @IBAction func monthButton(_ sender: UIButton) {
        buttonDecided = "Month"
        lineChartView.clear()
        
        // Fetch corresponding month data
        let averagesMonth = queryData(type: "Month") ?? [0]
        setLineChart("Month", Array:  averagesMonth)
        monthButtonVar.isHighlighted = true
        
        // Set the label to month being viewed
        monthDropdownButton.setTitle(months[countMonths], for: .normal)
        monthDropdownButton.isHidden = false
        arrowForward.isHidden = false
        arrowBackward.isHidden = false
        dateLabel.isHidden = false
        
        // update label with current month
        dateLabel.text = "\(months[countMonths]) \(years[countYears])"
    }
    
    @IBAction func weekButton(_ sender: UIButton) {
        buttonDecided = "Week"
        lineChartView.clear()
        
        // Fetch corresponding week data
        let averagesWeek = queryData(type: "Week") ?? [0]
        setLineChart("Week", Array: averagesWeek)
        weekButtonVar.isHighlighted = true
        
        // Set the label to week being viewed
        monthDropdownButton.setTitle(weeks[countWeeks], for: .normal)
        monthDropdownButton.isHidden = false
        arrowForward.isHidden = false
        arrowBackward.isHidden = false
        dateLabel.isHidden = false
        
        // update label with current month
        dateLabel.text = "\(months[countMonths]) \(years[countYears])"
        
    }

    @IBAction func yearButton(_ sender: UIButton) {
        buttonDecided = "Year"
        lineChartView.clear()
        totalDaysInTimePeriod = 12
        
        // Fetch corresponding year data
        let averagesYear = queryData(type: "Year") ?? [0]
        setLineChart("Year", Array: averagesYear)
        yearButtonVar.isHighlighted = true
        
        // Set the label to year being viewed
        monthDropdownButton.setTitle(years[countYears], for: .normal)
        monthDropdownButton.isHidden = false
        arrowForward.isHidden = false
        arrowBackward.isHidden = false
        dateLabel.isHidden = false
        
        // update label with current month
        dateLabel.text = "\(years[countYears])"
    }
    
    override func viewDidLoad() {
        // Hides buttons on initial view
        monthDropdownButton.isHidden = true
        arrowBackward.isHidden = true
        arrowForward.isHidden = true
        dateLabel.isHidden = true
        
        // Open database connection once
        do {
            db = try SQLiteDatabase.open()
            print("Successfully opened connection to database.")
        } catch {
            print("Unable to open database.")
        }
        super.viewDidLoad()
    }
    
    // setChart sets values of chart
    func setLineChart(_ type : String,  Array numbers : [Double]) {
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        let height = CGFloat(320)
        
        var lineChartEntry = [ChartDataEntry]() // this is the Array that will eventually be
        
        // Adds constraints to line graph
        NSLayoutConstraint.activate([
        lineChartView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
        lineChartView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
        lineChartView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,constant: -height),
        lineChartView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        // Formatting for line graph
        lineChartView.rightAxis.enabled = false
        lineChartView.leftAxis.enabled = true
        let yAxis = lineChartView.leftAxis
        
        yAxis.labelTextColor = .white
        yAxis.axisLineColor = .white
        yAxis.labelPosition = .outsideChart
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.labelTextColor = .white
        lineChartView.xAxis.axisLineColor = .white
        lineChartView.animate(xAxisDuration: 2.5)
    
    
        // Sets x-axis values as numbered days of month in week view
        var days: [String] = []
        if (type == "Week") {
            if (countWeeks != 4) {
                for i in startIndex + 1..<startIndex + 8 {
                    days.append(String(i))
                }
            }
            else {
                for i in startIndex + 1..<totalDaysInTimePeriod + 1 {
                    days.append(String(i))
                }
            }
        }
        else {
            // This is getting the correct x-axis values
            for j in 1..<totalDaysInTimePeriod + 1 {
                days.append(String(j))
            }
        }
        
        
        if (type == "Month") {
            for i in 0..<numbers.count {
                let value = ChartDataEntry(x: Double(i), y: numbers[i]) // set X and Y values status in a data chart entry
                lineChartEntry.append(value) // add it to the data set
            }
            lineChartView.xAxis.setLabelCount(15, force: false)
            lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:days)
            lineChartView.xAxis.granularity = 1
            
            // Adds title to graph
            self.lineChartView.chartDescription?.text = years[countYears]
        }
        else if (type == "Week") {
            //lineChartView.xAxis.setLabelCount(7, force: false)
            for i in 0..<numbers.count {
                let value = ChartDataEntry(x: Double(i), y: numbers[i]) // set X and Y values status in a data chart entry
                lineChartEntry.append(value) // add it to the data set
            }
            lineChartView.xAxis.setLabelCount(8, force: false)
            lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:days)
            lineChartView.xAxis.granularity = 1
            
            // Adds title to graph
            self.lineChartView.chartDescription?.text = months[countMonths] + ", " + years[countYears]
        }
        else if (type == "Year") {
            for i in 0..<numbers.count {
                let value = ChartDataEntry(x: Double(i),y: numbers[i]) // set X and Y values status
                // in a data chart entry
                lineChartEntry.append(value) // add it to the data set
            }
            lineChartView.xAxis.setLabelCount(12, force: false)
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:months)
            lineChartView.xAxis.granularity = 1
            self.lineChartView.chartDescription?.text = "Month of Past Year"
        }
        
        
        // Convert lineChartEntry to LineChartDataSet and add label for key
        let set1 = LineChartDataSet(entries: lineChartEntry, label: "Average Time Brushing")
        
        let data = LineChartData(dataSet: set1) // Object that will be added to the chart
        
        // Adds the line to the dataset
        self.lineChartView.data = data
        
        // Formatting for data in graph
        set1.mode = .cubicBezier
        set1.lineWidth = 3
        set1.drawFilledEnabled = true
        set1.drawCirclesEnabled = false
        
    }
}
