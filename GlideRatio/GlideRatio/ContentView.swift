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
                Text("WARNING")
                    .font(Font.myLargeFont)
                    .foregroundColor(.myErrorColor)
                    .padding(.vertical)
                
                Text("Bla, bla, bla ...")
                    .font(Font.myMediumFont)
                    .foregroundColor(.myPrimaryColor)
                
                Spacer()
                
                Button(action: {
                    self.showHelp = false
                }) {
                    Text("Close")
                        .font(Font.myLargeFont)
                        .foregroundColor(.mySecondaryColor)
                        .padding()
                }
                .padding(.vertical)
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppEnvironment())
    }
}
#endif
