//
//  HistoryViewController.swift
//  SmartBrush
//
//  Created by user203264 on 10/23/21.
//

import Foundation
import UIKit
import Charts
import CoreBluetooth
import SwiftUI

var db: SQLiteDatabase?
let heartRateServiceCBUUID = CBUUID(string: "13E9C5BF-43B9-4F7B-BE87-7BEAE6464A2D")
let accelXCharacteristicCBUUI = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
let accelYCharacteristicCBUUI = CBUUID(string: "F73ECE94-C2EB-480B-AB97-9A1513D8DEF1")
let accelZCharacteristicCBUUI = CBUUID(string: "07081583-CA83-4178-82DB-873E231831EA")

var totalMovement = 0.0

var collect = false

class Movement: ObservableObject {
    @Published var movementAmount: Double = 0.0
    
    init(_ movementValue: Double) {
        movementAmount = movementValue
    }
    
    func setMovement(_ amount: Double) {
        movementAmount = amount
    }
}

var movement = Movement(0.0)

class RealTimeViewController: UIViewController {
    @IBOutlet var statusButton: UIButton!
    
    @IBOutlet var timerLabel: UILabel!
    
    @IBOutlet weak var barChartView: BarChartView!
    
    var countdownTimer: Timer!
    var totalTime = 10
    
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    
    var connectionStatus: Bool = false
    
    // date and time values
    var year: Int? = 2000
    var month: Int? = 1
    var day: Int? = 1
    var time: String = "15:40:20" // hour:minute:second in 24 hour time clock
    let calendar = Calendar.current
    var dayOfWeek: Int? = 1
    var totalDaysInMonth: Int? = 30
    
    func startTimer() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime() {
        timerLabel.text = "\(timeFormatted(totalTime))"
        
        if totalTime != 0 {
            totalTime -= 1
        } else {
            endTimer()
        }
        @StateObject var value = UserAuthentication()
        
    }
    
    func endTimer() {
        statusButton.setTitle("Start", for: .normal)
        statusButton.isUserInteractionEnabled = true
        collect = false
        //        print(movementList)
        totalTime = 10
        timerLabel.text = "\(timeFormatted(totalTime))"
        countdownTimer.invalidate()
        
        // SEND TOTAL MOVEMENT + TIME TO THE DATABASE
        do {
            let averageMovement = totalMovement/Double(totalTime)
            updateCurrentTime()
            
            print("Year \(Int32(year!))")
            print("Month \(Int32(month!))")
            print("Day \(Int32(day!))")
            print("Time \(time)")
            print("Day Of Week \(Int32(dayOfWeek!))")
            print("Average Movement \(totalMovement/Double(totalTime))")
            
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(year!), average: averageMovement, month: Int32(month!), day: Int32(day!), time: time as NSString,  dayOfWeek: Int32(dayOfWeek!), numberOfDaysInMonth: Int32(totalDaysInMonth!)))
        }
        catch {
            print("Error with inserting data")
        }
        
    }
    
    func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        
        return String(format: "%01d:%02d", minutes, seconds)
    }
    
    @IBAction func StartTimerPressed(_ sender: UIButton) {
        statusButton.setTitle("Brush", for: .normal)
        statusButton.isUserInteractionEnabled = false
        collect = true
        totalMovement = 0.0
        updateCurrentTime()
        startTimer()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Open database connection and create table structure
        /*do {
            db = try SQLiteDatabase.open()
            db?.deleteDatabase()
        }
        catch {
            print("Deleted database")
        }*/

        do {
            db = try SQLiteDatabase.open()
            print("Successfully opened connection to database.")
            try db?.createTable(table: ToothBrushData.self)
        } catch {
            print("Unable to open database.")
        }
        
        
        do {
            
            // Example of how data should be inserted
            updateCurrentTime()
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(year!), average: 2.2, month: Int32(month!), day: Int32(day!), time: time as NSString,  dayOfWeek: Int32(dayOfWeek!), numberOfDaysInMonth: Int32(totalDaysInMonth!)))
                   
            
            // MOCK DATA DO NOT USE AS EXAMPLE
            
            // Testing if averaging on same day with multiple values
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2019), average: 1.2, month: Int32(4), day: Int32(29), time: time as NSString,  dayOfWeek: Int32(2), numberOfDaysInMonth: Int32(30)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2019), average: 1.5, month: Int32(4), day: Int32(29), time: time as NSString,  dayOfWeek: Int32(2), numberOfDaysInMonth: Int32(30)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2019), average: 2.0, month: Int32(4), day: Int32(29), time: time as NSString,  dayOfWeek: Int32(2), numberOfDaysInMonth: Int32(30)))
                   
            // Testing multiple days in a month
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.3, month: Int32(7), day: Int32(11), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.4, month: Int32(7), day: Int32(12), time: time as NSString,  dayOfWeek: Int32(2), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.2, month: Int32(7), day: Int32(13), time: time as NSString,  dayOfWeek: Int32(3), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 2.1, month: Int32(7), day: Int32(14), time: time as NSString,  dayOfWeek: Int32(4), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.12, month: Int32(7), day: Int32(15), time: time as NSString,  dayOfWeek: Int32(5), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.456, month: Int32(7), day: Int32(16), time: time as NSString,  dayOfWeek: Int32(6), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.7, month: Int32(7), day: Int32(17), time: time as NSString,  dayOfWeek: Int32(7), numberOfDaysInMonth: Int32(31)))
            
            
            // Testing every month in one year
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.3, month: Int32(1), day: Int32(11), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.4, month: Int32(2), day: Int32(12), time: time as NSString,  dayOfWeek: Int32(2), numberOfDaysInMonth: Int32(28)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.2, month: Int32(3), day: Int32(13), time: time as NSString,  dayOfWeek: Int32(3), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 2.1, month: Int32(4), day: Int32(14), time: time as NSString,  dayOfWeek: Int32(4), numberOfDaysInMonth: Int32(30)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.12, month: Int32(5), day: Int32(15), time: time as NSString,  dayOfWeek: Int32(5), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.456, month: Int32(6), day: Int32(16), time: time as NSString,  dayOfWeek: Int32(6), numberOfDaysInMonth: Int32(30)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.7, month: Int32(7), day: Int32(17), time: time as NSString,  dayOfWeek: Int32(7), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.3, month: Int32(8), day: Int32(11), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.4, month: Int32(9), day: Int32(12), time: time as NSString,  dayOfWeek: Int32(2), numberOfDaysInMonth: Int32(30)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.2, month: Int32(10), day: Int32(13), time: time as NSString,  dayOfWeek: Int32(3), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 2.1, month: Int32(11), day: Int32(14), time: time as NSString,  dayOfWeek: Int32(4), numberOfDaysInMonth: Int32(30)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2020), average: 1.12, month: Int32(12), day: Int32(15), time: time as NSString,  dayOfWeek: Int32(5), numberOfDaysInMonth: Int32(30)))
            
            
            // Data
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.3, month: Int32(12), day: Int32(1), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.7, month: Int32(12), day: Int32(2), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 2.0, month: Int32(12), day: Int32(3), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.2, month: Int32(12), day: Int32(4), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 2.3, month: Int32(12), day: Int32(5), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
            try db?.insertData(ToothBrushData: ToothBrushData(year:Int32(2021), average: 1.7, month: Int32(12), day: Int32(6), time: time as NSString,  dayOfWeek: Int32(1), numberOfDaysInMonth: Int32(31)))
               }
               catch {
                   print("Error with inserting data")
               }
        
            
        timerLabel.text = "\(timeFormatted(totalTime))"
        statusButton.setTitle("Please Connect Device", for: .normal)
        statusButton.isUserInteractionEnabled = false
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        updateCurrentTime() // get the current time value
    }
    
    func weekDay(date: Date) -> Int {
        let components = calendar.dateComponents([.weekday], from:date)
        return components.weekday! - 1
    }
    
    func updateCurrentTime(){
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        
        let dateItems = dateString.components(separatedBy: "-")

        year = Int(dateItems[0])
        month = Int(dateItems[1])
        day = Int(dateItems[2])
        time = dateItems[3]
    }
    
    
   
}

extension RealTimeViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
            statusButton.setTitle("Please Connect Device", for: .normal)
            statusButton.isUserInteractionEnabled = false
            //            print(movementList)
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print(peripheral)
        heartRatePeripheral = peripheral
        heartRatePeripheral.delegate = self
        
        // set the UUID label to the device we connected to
        //        UUIDLabel.text = peripheral.name
        
        centralManager.stopScan()
        centralManager.connect(heartRatePeripheral)
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        
        statusButton.setTitle("Start", for: .normal)
        statusButton.isUserInteractionEnabled = true
        connectionStatus = true // we're connected
        
        heartRatePeripheral.discoverServices(nil) // discover the services of the device
    }
    
}

extension RealTimeViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
                
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        switch characteristic.uuid {
        case accelXCharacteristicCBUUI:
//            print(characteristic.value ?? "no value")
            
            let bytes: [UInt8] =  [0x44, 0xFA, 0x00, 0x00]
            let data = Data(bytes: bytes, count: 4)
            let x = Double(floatValue(data: (characteristic.value ?? data) as Data))
            
            if collect {
                if x > 1.00 || x < -1.00 {
                    print("X: \(x)")
                    totalMovement += abs(x) / 500
                    
                    if totalMovement <= 400 {
                        movement.movementAmount = totalMovement
                    }
                }
            }
        case accelYCharacteristicCBUUI:
            
            let bytes: [UInt8] =  [0x44, 0xFA, 0x00, 0x00]
            let data = Data(bytes: bytes, count: 4)
            let y = Double(floatValue(data: (characteristic.value ?? data) as Data))
            
            
            if collect {
                if y > 1.00 || y < -1.00 {
                    print("Y: \(y)")
                    totalMovement += abs(y) / 500
                    
                    if totalMovement <= 400 {
                        movement.movementAmount = totalMovement
                    }
                }
            }
            
        case accelZCharacteristicCBUUI:
            
            let bytes: [UInt8] =  [0x44, 0xFA, 0x00, 0x00]
            let data = Data(bytes: bytes, count: 4)
            let z = Double(floatValue(data: (characteristic.value ?? data) as Data))
            
            
            if collect {
                print("Z: \(z)")
                if z > 1.00 || z < -1.00 {
                    print("X: \(z)")
                    totalMovement += abs(z) / 500
                    
                    if totalMovement <= 400 {
                        movement.movementAmount = totalMovement
                    }
                }
            }
            
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    func floatValue(data: Data) -> Float {
        return Float(bitPattern: UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) }))
    }
}

class UserAuthentication: ObservableObject {
    var x = 0.5 {
        willSet {
            objectWillChange.send()
        }
    }
}

struct BrushProgress: View {
    @ObservedObject var movementVlaue = movement
    
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            Color.orange
            Rectangle().frame(width: 100, height: 400).foregroundColor(Color(UIColor.black))
            
            Rectangle().frame(width: 100, height: CGFloat(movementVlaue.movementAmount)).foregroundColor(Color(UIColor.green))
            
            //            Label("\(movementVlaue.movementAmount)", systemImage: "bolt.fill")
        }
    }
    
}

struct BarContent: View {
    var body: some View{
        BrushProgress()
    }
}

struct RealTimeUI_Previews: PreviewProvider {
    static var previews: some View {
        BarContent()
    }
}


class SwiftUIViewHostingController: UIHostingController<BarContent> {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: BarContent())
    }
}


