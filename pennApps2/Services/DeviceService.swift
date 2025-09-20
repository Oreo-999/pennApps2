import Foundation
import UIKit
import Combine

class DeviceService: ObservableObject {
    @Published var deviceId: String
    
    init() {
        self.deviceId = DeviceService.getOrCreateDeviceId()
    }
    
    private static func getOrCreateDeviceId() -> String {
        let key = "device_id"
        
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    func resetDeviceId() {
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "device_id")
        deviceId = newId
    }
}
