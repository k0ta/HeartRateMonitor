//
//  ViewController.swift
//  HeartRateMonitor
//
//  Created by Kota Sato on 1/12/16.
//  Copyright © 2016 Kota Sato. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var deviceNameLbl: UILabel!
    @IBOutlet weak var bpmValueLbl: UILabel!
    
    var centralManager:CBCentralManager!
    var connectingPeripheral:CBPeripheral!

//    let kServiceUUIDHeartRate = "0x180D";
    let kCharacteristicUUIDHeartRateMeasurement = "0x2A37";
    let serviceUUID = CBUUID(string: "0x180D");
//    let kServiceUUIDHeartRate = "180D";
//    let kCharacteristicUUIDHeartRateMeasurement = "2A37";

    // =============================================================
    // UIViewController
    // =============================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // =============================================================
    // CBCentralManagerDelegate
    // =============================================================
    func centralManagerDidUpdateState(central: CBCentralManager){
    
        switch central.state{
        case .PoweredOn:
            print("Bluetooth: poweredOn")
            // HeartRateのサービスを持ったデバイスのみ檢索する
            let serviceUUIDs:[CBUUID] = [serviceUUID]
            // HeartRateのデバイスに接続済みの場合はそのデバイスを利用
            let lastPeripherals = centralManager.retrieveConnectedPeripheralsWithServices(serviceUUIDs)
            print("lastPeripherals.count: \(lastPeripherals.count)")
            if lastPeripherals.count > 0{
                let device: CBPeripheral! = lastPeripherals.last;
                print("use lastPeripherals: \(device.name)")
                connectingPeripheral = device
                connectingPeripheral.delegate = self
                centralManager.connectPeripheral(connectingPeripheral, options: nil)
            }
            else {
                // HeartRateのデバイスが未接続の場合はデバイスの検索を行う
                centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: nil)
            }
            
        case .PoweredOff:
            let title = "Failed to connect device."
            let msg = "Bluetooth: powerOff"
            showAlert(title,msg: msg)
        default:
            let title = "Failed to connect device."
            let msg = "Bluetooth.status:  \(String(central.state.rawValue))"
            showAlert(title,msg: msg)
        }
    }
    
    // bluetoothデバイス発見時
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber){
        print("discover device: \(peripheral.name)")
        connectingPeripheral = peripheral
        connectingPeripheral.delegate = self
        //発見したデバイスに接続
        centralManager.connectPeripheral(connectingPeripheral, options: nil)
    }

    // bluetoothデバイスへの接続時
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("connect device: \(peripheral.name)")
        connectingPeripheral = peripheral;
        deviceNameLbl.text = peripheral.name!
        //接続したデバイスのHeartRateサービスを探す
        peripheral.discoverServices([self.serviceUUID])
    }
    
    // bluetoothデバイスへの接続失敗時
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?){
        print("Failed to Connect: \(peripheral.name)")

    }

    // =============================================================
    // CBPeripheralDelegate
    // =============================================================
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if (error != nil) {
            print("Failed to discover services " + error!.localizedDescription)
            return
        }
        print("Discover services: \(peripheral.services)")
        for service in peripheral.services as [CBService]!{
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (error != nil) {
            print("Failed to discover services " + error!.localizedDescription)
            return
        }
        print("Discover characteristics for service. service.UUID: \(service.UUID)")
        if service.UUID == self.serviceUUID{
            for characteristic in service.characteristics! {
                switch characteristic.UUID.UUIDString{
                case "2A37": 
                    // HeartRateMeasurement
                    // Set notification on heart rate measurement
                    print("Found a Heart Rate Measurement Characteristic")
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
//                    case "2A38":
//                        // Read body sensor location
//                        println("Found a Body Sensor Location Characteristic")
//                        peripheral.readValueForCharacteristic(characteristic)
//                        
//                    case "2A39":
//                        // Write heart rate control point
//                        println("Found a Heart Rate Control Point Characteristic")
//                        
//                        var rawArray:[UInt8] = [0x01];
//                        let data = NSData(bytes: &rawArray, length: rawArray.count)
//                        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
                        
                    default:
                        print(characteristic.UUID.UUIDString)
                }
                    
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        if (error != nil) {
            print("Failed to read value " + error!.localizedDescription)
            return
        }
        print("read value raw: \(characteristic.value)")
        switch characteristic.UUID.UUIDString{
        case "2A37": //HeartRateMeasurement
            update(characteristic.value!)
        default:
            print(characteristic.UUID.UUIDString)
        }
    }
    
    // =============================================================
    // Logic
    // =============================================================
    func update(heartRateData:NSData){
        
        var buffer = [UInt8](count: heartRateData.length, repeatedValue: 0x00)
        heartRateData.getBytes(&buffer, length: buffer.count)
        
        var bpm:UInt16?
        if (buffer.count >= 2){
            if (buffer[0] & 0x01 == 0){
                bpm = UInt16(buffer[1]);
            }else {
                bpm = UInt16(buffer[1]) << 8
                bpm =  bpm! | UInt16(buffer[2])
            }
        }
        
        if let actualBpm = bpm{
            print("bpm: \(actualBpm )")
            bpmValueLbl.text = String(actualBpm);
        }else {
            print("bpm: \(bpm )")
            bpmValueLbl.text = String(bpm);
        }
    }
    
    func showAlert(title:String, msg: String){
        print("title: " + title + "msg: " + msg)
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
}

