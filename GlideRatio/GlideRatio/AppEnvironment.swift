//
//  AppEnvironment.swift
//  GlideRatio
//
//  Created by Sergey Muravev on 10.03.2020.
//  Copyright © 2020 Sergey Muravev. All rights reserved.
//

import Combine
import SwiftUI
import CoreMotion

enum GlideSource {
    case fromTakeOff
    case fromLanding
}

final class AppEnvironment: ObservableObject {
    
    @Published var calibration: Loadable<String> = .notRequested
    
    @Published var glideRatio: Loadable<Double> = .notRequested
    
    @Published var glideSource: GlideSource?
    
    private let motionManager = CMMotionManager()
    
    private let deviceMotionQueue: OperationQueue
    
    init() {
        let queueNamePrefix = "me.smuravev.GlideRatio"
        deviceMotionQueue = OperationQueue()
        deviceMotionQueue.name = "\(queueNamePrefix).deviceMotionQueue"
        
        initObservers()
    }
    
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Observers

extension AppEnvironment {
    
    private func initObservers() {
    }
}

// MARK: - CoreMotion

extension AppEnvironment {
    
    func startSensors() {
        self.calibration = .isLoading(last: "Calibration")
        self.glideRatio = .isLoading(last: nil)
        self.glideSource = nil

        delay(2) {
            guard self.motionManager.isDeviceMotionAvailable else {
                self.calibration = .failed("Motion service not supported - make sure accelerometer and magnetometer (compass) installed on your device.")
                return
            }
            
            self.motionManager.deviceMotionUpdateInterval = 0.1
            if !self.motionManager.isDeviceMotionActive {
                // using: .xArbitraryZVertical | .xArbitraryCorrectedZVertical | .xMagneticNorthZVertical | .xTrueNorthZVertical
                self.motionManager.startDeviceMotionUpdates(to: self.deviceMotionQueue) { deviceMotion, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.glideRatio = .failed(error)
                            self.glideSource = nil
                            return
                        }
                        
                        guard let deviceMotion = deviceMotion else {
                            return
                        }
                        
                        // Normalize the gravity (accelerometer) vector
                        let normalizedGravity = sqrt(
                            deviceMotion.gravity.x * deviceMotion.gravity.x
                            + deviceMotion.gravity.y * deviceMotion.gravity.y
                            + deviceMotion.gravity.z * deviceMotion.gravity.z
                        )
                        
                        let tiltGravity: (x: Double, y: Double, z: Double) = (
                            x: deviceMotion.gravity.x / normalizedGravity,
                            y: deviceMotion.gravity.y / normalizedGravity,
                            z: deviceMotion.gravity.z / normalizedGravity
                        )
                        
                        let tiltRadians = acos(tiltGravity.z)
                        let tiltDegrees = tiltRadians * 180.0 / Double.pi
                        
                        let inclinationDegrees = 180 - tiltDegrees
                        
                        var angle: Double?
                        if inclinationDegrees > 0 && inclinationDegrees < 90 { // from takeoff
                            angle = 90 - inclinationDegrees
                            self.glideSource = .fromTakeOff
                        } else if inclinationDegrees > 90 && inclinationDegrees < 180 { // from landing
                            angle = inclinationDegrees - 90
                            self.glideSource = .fromLanding
                        } else {
                            self.glideSource = nil
                        }
                        
                        if let angle = angle {
                            let angleRadians = angle * Double.pi / 180.0
                            let cotan = 1.0 / tan(angleRadians)
                            
                            self.glideRatio = .loaded(cotan)
                        } else {
                            self.glideRatio = .loaded(0.0)
                        }
                    }
                }
            }
            
            self.calibration = .loaded("Calibration done.")
        }
    }
    
    func stopSensors() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
            deviceMotionQueue.cancelAllOperations()
        }
        
        calibration = .notRequested
        glideRatio = .notRequested
        glideSource = nil
    }
}

// MARK: - Helpers

extension Double {
    
    // Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension String: Identifiable {
    public var id: String? {
        self
    }
}

extension String {

    public func escape() -> String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    public func unescape() -> String? {
        return self.removingPercentEncoding
    }

    public func toUrl() -> URL? {
        guard let escaped = self.escape() else {
            return URL(string: self)
        }

        return URL(string: escaped)
    }
    
    public func localized(_ bundle: Bundle? = nil) -> String {
        return NSLocalizedString(self, bundle: bundle ?? Bundle.main, comment: "")
    }
    
    public func localized(_ bundle: Bundle? = nil, params: CVarArg...) -> String {
        return String(format: self.localized(bundle), arguments: params)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: closure)
}

extension UIColor {
    
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
    
    public convenience init?(hexRgba hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}

extension Color {

    init(uiColor: UIColor) {
        self.init(
            red: Double(uiColor.rgba.red),
            green: Double(uiColor.rgba.green),
            blue: Double(uiColor.rgba.blue),
            opacity: Double(uiColor.rgba.alpha)
        )
    }
}

// MARK: - Styles

extension UIColor {
    
    static var myBackgroundColor: UIColor {
        UIColor.black
    }
    
    static var myPrimaryColor: UIColor {
        UIColor.white
    }
    
    static var mySecondaryColor: UIColor {
        UIColor(hexRgba: "#fdd710ff") ?? UIColor.yellow
    }
    
    static var myErrorColor: UIColor {
        UIColor.red
    }
}

extension Color {
    
    static var myBackgroundColor: Color {
        Color(uiColor: UIColor.myBackgroundColor)
    }
    
    static var myPrimaryColor: Color {
        Color(uiColor: UIColor.myPrimaryColor)
    }
    
    static var mySecondaryColor: Color {
        Color(uiColor: UIColor.mySecondaryColor)
    }
    
    static var myErrorColor: Color {
        Color(uiColor: UIColor.myErrorColor)
    }
}

extension Font {
    
    static var myHugeFont: Font {
        Font.custom("Arial Rounded MT", size: 48)
    }
    
    static var myHugeBoldFont: Font {
        Font.custom("Arial Rounded MT Bold", size: 48)
    }
    
    static var myLargeFont: Font {
        Font.custom("Arial Rounded MT", size: 24)
    }
    
    static var myLargeBoldFont: Font {
        Font.custom("Arial Rounded MT Bold", size: 24)
    }
    
    static var myMediumFont: Font {
        Font.custom("Arial Rounded MT", size: 16)
    }
    
    static var myMediumBoldFont: Font {
        Font.custom("Arial Rounded MT Bold", size: 16)
    }
    
    static var mySmallFont: Font {
        Font.custom("Arial Rounded MT", size: 12)
    }
    
    static var mySmallBoldFont: Font {
        Font.custom("Arial Rounded MT Bold", size: 12)
    }
    
    static var myTinyFont: Font {
        Font.custom("Arial Rounded MT", size: 10)
    }
    
    static var myTinyBoldFont: Font {
        Font.custom("Arial Rounded MT Bold", size: 10)
    }
}
