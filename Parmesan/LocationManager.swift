//
//  LocationManager.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/6/1.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    private var hasRequestedLocation = false // 用于标记是否已经请求过定位

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        guard !hasRequestedLocation else { return } // 如果已经请求过定位，则直接返回

        hasRequestedLocation = true // 标记已经请求过定位

        // 请求定位权限
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if CLLocationManager.locationServicesEnabled() {
            manager.desiredAccuracy = kCLLocationAccuracyBest // 设置定位精度
            manager.requestLocation() // 只请求一次定位
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard location == nil else { return } // 只获取第一次定位结果

        location = locations.last
        manager.stopUpdatingLocation() // 获取到定位后停止更新
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
}
