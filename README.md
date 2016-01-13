ReadMe
========

心拍数をモニタリングするアプリのPoc
BLEの標準プロトコルのHeart Rateを使ってウェアラブルデバイスへ接続しています。

Point
----------------
* Heart Rateを提供するデバイスのみ檢索し接続する  
  Assigned Number: 0x180D  
  Link: https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.heart_rate.xml  
  ex) centralManager.scanForPeripheralsWithServices(serviceUUIDs, options: nil)


* HeartRateMeasurement の通知を設定する
  ex) peripheral.setNotifyValue(true, forCharacteristic: characteristic)


* ウェアラブルからの通知を受け取りBPMを取得する
  戻り値にはFlagが含まれているため、下記Linkを元に、何桁目にBPMが記載されているかを判断する必要がある  
  詳細は func getBpm を参照ください。  
  Link: https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.heart_rate_measurement.xml
