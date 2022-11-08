//
//  ConnectionViewController.swift
//  SmartBrush
//
//  Created by user203264 on 10/26/21.
//
//
//import UIKit
//import Charts
//import CoreBluetooth
//
//let heartRateServiceCBUUID = CBUUID(string: "13E9C5BF-43B9-4F7B-BE87-7BEAE6464A2D")
//let accelXCharacteristicCBUUI = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
//let accelYCharacteristicCBUUI = CBUUID(string: "F73ECE94-C2EB-480B-AB97-9A1513D8DEF1")
//let accelZCharacteristicCBUUI = CBUUID(string: "07081583-CA83-4178-82DB-873E231831EA")
//
//
//class ConnectionViewController:UIViewController {
//
//    
//    @IBOutlet var connectionStatusLabel: UILabel!
//    @IBOutlet var UUIDLabel: UILabel!
//    @IBOutlet var connectButton: UIButton!
//    @IBOutlet var moveValueLabel: UILabel!
//    
//    var centralManager: CBCentralManager!
//    var heartRatePeripheral: CBPeripheral!
//
//    var connectionStatus: Bool = false
//    
//    var totalMovement: Double = 60 // keep track of the total movement from X,Y,Z
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // set the default view of the labels
//        connectionStatusLabel.textColor = UIColor.systemRed // red is not connected
//        connectButton.isUserInteractionEnabled = !connectionStatus // if it's not connected, enable button
//        moveValueLabel.text = "0" // start at zero
//        
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//        
//        createBarChart()
//        
//    }
//    
//    private func createBarChart() {
//    //        @StateObject var value = UserAuthentication()
//            // Create bar chart
//            let barChart = BarChartView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
//            
//            // Configure the axis
//            var entries = [BarChartDataEntry]()
//            
//    //        for i in 0..<1 {
//    //            entries.append(BarChartDataEntry(x: Double(i), y: Double.random(in: 1...30)))
//    //        }
//            
//            entries.append(BarChartDataEntry(x: Double(0), y: totalMovement))
//            let set = BarChartDataSet(entries: entries)
//            let data = BarChartData(dataSet: set)
//            
//            barChart.data = data
//            // Configure the legend
//            barChart.legend.enabled = false
//            barChart.xAxis.enabled = false
//            // Supply Data
//            
//            view.addSubview(barChart)
//            barChart.center = view.center
//        }
//
//}
//
//extension ConnectionViewController: CBCentralManagerDelegate{
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        switch central.state {
//          case .unknown:
//            print("central.state is .unknown")
//          case .resetting:
//            print("central.state is .resetting")
//          case .unsupported:
//            print("central.state is .unsupported")
//            totalMovement += Double(40)
//            createBarChart()
//          case .unauthorized:
//            print("central.state is .unauthorized")
//          case .poweredOff:
//            print("central.state is .poweredOff")
//          case .poweredOn:
//            print("central.state is .poweredOn")
//            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
//                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
//        print(peripheral)
//        heartRatePeripheral = peripheral
//        heartRatePeripheral.delegate = self
//        
//        // set the UUID label to the device we connected to
//        UUIDLabel.text = peripheral.name
//
//        centralManager.stopScan()
//        centralManager.connect(heartRatePeripheral)
//
//    }
//    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        print("Connected!")
//        // change the labels and things
//        connectionStatusLabel.textColor = UIColor.systemGreen // connection is good
//        connectionStatusLabel.text = "Connected"
//        connectionStatus = true // we're connected
//        connectButton.isUserInteractionEnabled = !connectionStatus // it's connect, disable button
//        
//        heartRatePeripheral.discoverServices(nil) // discover the services of the device
//
//    }
//    
//}
//
//extension ConnectionViewController: CBPeripheralDelegate {
//
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//
//        for service in services {
//            print(service)
//            peripheral.discoverCharacteristics(nil, for: service)
//
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
//                    error: Error?) {
//      guard let characteristics = service.characteristics else { return }
//
//      for characteristic in characteristics {
//          print(characteristic)
//          if characteristic.properties.contains(.read) {
//              print("\(characteristic.uuid): properties contains .read")
//              peripheral.readValue(for: characteristic)
//
//          }
//          if characteristic.properties.contains(.notify) {
//              print("\(characteristic.uuid): properties contains .notify")
//              peripheral.setNotifyValue(true, for: characteristic)
//          }
//
//      }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
//                    error: Error?) {
//      switch characteristic.uuid {
//        case accelXCharacteristicCBUUI:
//            print(characteristic.value ?? "no value")
//          // WARNING FORCED UNWRAPING to a string. NOT GOOD
//          let movementValue = String(decoding: characteristic.value!, as: UTF8.self)
//          let bytes: [UInt8] =  [0x44, 0xFA, 0x00, 0x00]
//          let data = Data(bytes: bytes, count: 4)
//          print(data) // <44fa0000>
//          let f = floatValue(data: (characteristic.value ?? data) as Data)
//          print(f) // 2000.0
//        
//          totalMovement += Double(f)
//          moveValueLabel.text = "\(f)"
//          createBarChart()
//
//          
//        default:
//            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
//      }
//    }
//    
//    
//    // calculate the total movement during this measurement
//    private func movementCalculation(from characteristic: CBCharacteristic) -> Int{
//        
//        guard let charactersiticData = characteristic.value
//        
//        return 0
//    }
//    
//    func floatValue(data: Data) -> Float {
//            return Float(bitPattern: UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) }))
//        }
//
//    
//}
