//
//  CameraView.swift
//  GlideRatio
//
//  Created by Sergey Muravev on 10.03.2020.
//  Copyright © 2020 Sergey Muravev. All rights reserved.
//

import Foundation
import SwiftUI

class CameraViewCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        guard let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//            return
//        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    }
}

struct CameraView: UIViewControllerRepresentable {
    
    var onInitView = { (uiViewController: UIViewControllerType) in }
    
    var onUpdateView = { (uiViewController: UIViewControllerType) in }
    
    typealias UIViewControllerType = UIImagePickerController
    
    typealias Coordinator = CameraViewCoordinator
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIImagePickerController {
        let uiViewController = UIImagePickerController()
        uiViewController.delegate = context.coordinator
        
        self.onInitView(uiViewController)
        
        return uiViewController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CameraView>) {
        self.onUpdateView(uiViewController)
    }
    
    func makeCoordinator() -> CameraView.Coordinator {
        return CameraViewCoordinator()
    }
}
