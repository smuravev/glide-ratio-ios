//
//  ContentView.swift
//  GlideRatio
//
//  Created by Sergey Muravev on 10.03.2020.
//  Copyright © 2020 Sergey Muravev. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
        
    @EnvironmentObject var appEnvironment: AppEnvironment
    
    @State private var showHelp = false
    
    var body: some View {
        let calibration = self.appEnvironment.calibration
        let glideRatio = self.appEnvironment.glideRatio
        let glideSource = self.appEnvironment.glideSource
        
        var iconName = "line.horizontal.3"
        var iconTitle = "flat"
        var glideRatioTitle = ""
        
        if let error = glideRatio.error {
            glideRatioTitle = error.localizedDescription
        } else if let value = glideRatio.value, value <= 20 {
            if glideSource == .fromTakeOff {
                iconName = "arrow.down.left"
                iconTitle = "from takeoff"
            } else if glideSource == .fromLanding {
                iconName = "arrow.up.right"
                iconTitle = "from landing"
            }

            glideRatioTitle = "\(value.rounded(toPlaces: 1))"
        }
        
        return ZStack {
            Rectangle()
                .fill(Color.myBackgroundColor)
                .edgesIgnoringSafeArea(.all)

            if calibration.isLoading || calibration.isNotRequested {
                // Calibration is in loading status or not requested yet.
                VStack {
                    Text(calibration.value ?? "Loading")
                        .font(Font.myLargeBoldFont)
                        .foregroundColor(.myPrimaryColor)
                        .padding()

                    ActivityIndicator(isAnimating: true) { (indicator: UIActivityIndicatorView) in
                        indicator.color = .myPrimaryColor
                        indicator.style = .large
                        indicator.hidesWhenStopped = false
                    }
                }
            } else if calibration.isFailed {
                VStack {
                    Text("ERROR :(")
                        .font(Font.myHugeBoldFont)
                        .foregroundColor(.myErrorColor)
                        .padding(.bottom, 20)
                    
                    Text(calibration.error?.localizedDescription ?? "Unknown issue.")
                        .font(Font.myMediumFont)
                        .foregroundColor(.myPrimaryColor)
                    
                    Text("Contact to:")
                        .font(Font.myLargeFont)
                        .foregroundColor(.mySecondaryColor)
                        .padding(.top, 20)
                    
                    Text("sergey.muravev@gmail.com")
                        .font(Font.myLargeFont)
                        .foregroundColor(.mySecondaryColor)
                }
                .padding()
            } else if calibration.isLoaded {
                // CAMERA
                CameraView(
                    onInitView: { (uiViewController: UIImagePickerController) in
                        uiViewController.sourceType = .camera
                        uiViewController.cameraDevice = .rear
                        uiViewController.cameraCaptureMode = .photo
                        uiViewController.showsCameraControls = false
                        uiViewController.allowsEditing = false
//                        uiViewController.view.frame = self.view.bounds
//                        uiViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    },

                    onUpdateView: { (uiViewController: UIImagePickerController) in
                    }
                )
                .edgesIgnoringSafeArea(.all)
                
                // AIM
                GeometryReader { geometry in
                    Image(systemName: "plus.circle")
                        .resizable()
                        .clipped()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.myPrimaryColor)
                        .frame(width: 30, height: 30, alignment: .center)
                        .position(x: geometry.size.width / 2.5, y: geometry.size.height / 2)
                }
                
                // TOOLBAR - isLoaded
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Button(action: {
                            self.showHelp = true
                        }) {
                            VStack {
                                Image(systemName: "questionmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.mySecondaryColor)
                                
                                Text("read me")
                                    .font(Font.mySmallFont)
                                    .foregroundColor(.mySecondaryColor)
                            }
                        }
                        .padding()
                        .frame(width: 80)
                        .sheet(isPresented: self.$showHelp) {
                            self.helpContent
                        }
                        
                        Spacer()
                        
                        Text(glideRatioTitle)
                            .font(Font.myHugeBoldFont)
                            .foregroundColor(.myPrimaryColor)
                        
                        Spacer()
                        
                        VStack {
                            Image(systemName: iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.myPrimaryColor)

                            Text(iconTitle)
                                .font(Font.mySmallFont)
                                .foregroundColor(.myPrimaryColor)
                        }
                        .frame(width: 70)
                    }
                    .padding()
                }
                .padding(.trailing, 20)
            }
        }
    }
    
    private var helpContent: some View {
        ZStack {
            Rectangle()
                .fill(Color.myBackgroundColor)

            VStack {
                ScrollView(.vertical, showsIndicators: true) {
                    Text("NOTICE")
                        .font(Font.myLargeFont)
                        .foregroundColor(.myErrorColor)
                        .padding(.vertical)
                    
                    Text(disclaimerText)
                        .font(Font.myMediumFont)
                        .foregroundColor(.myPrimaryColor)
                }
                
                Button(action: {
                    self.showHelp = false
                }) {
                    Text("Close")
                        .font(Font.myLargeFont)
                        .foregroundColor(.mySecondaryColor)
                }
                .padding(.vertical)
            }
        }
    }
    
    private let disclaimerText = """
1. Disclaimer and exclusion of liability Exemption from liability, waiver of claims, assumption of risk.

1.1. Assumption of risk.

Any Paragliding, Speed flying (Speed riding), Base jumping and other Paralpinisme sport activities involve certain risks of personal injury or death for the user of the application and for third parties.

By using the application, you agree to assume and accept any and all known and unknown, and likely and unlikely risks of injury.

The risks inherent in these sports can be reduced to a large extent by observing the warning guidelines contained in the manuals of your equipment and by using common sense.

1.2. Exclusion of liability, waiver of claims.

By using the application, you agree to the following points, to the extent permitted by law.

To waive any and all claims however they arise from use of the application, which you have or may in the future have against authors and any other parties.

1.3. To release.

Authors of the application and any other parties from any and all claims for loss, damage, injury or expense that you, your next of kin or relations or any other user of the application may suffer as a result of use of the application, including liability arising under law and contract on the part of authors and any other parties in the distribution, development and usage of the application.

In the event of death or disability, all of the provisions contained herein shall be effective and binding upon the user’s heirs, next of kin and relatives, executors, administrators, assigns and legal representatives. Application authors and all other parties have not made any oral or written representations and expressly deny having done so, with the exception of what is set out herein and in the application manual.
"""
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppEnvironment())
    }
}
#endif
