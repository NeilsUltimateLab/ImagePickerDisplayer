//
//  ImagePickerDisplaying+SwiftUI.swift
//  ImagePickerDisplayer
//
//  Created by Neil on 03/12/20.
//

import UIKit
import SwiftUI

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onSelection: ((Result<URL, AppError>)->Void)?
    
    typealias UIViewControllerType = UIImagePickerController
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = self.sourceType
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    class Coordinator: NSObject {
        var onSelection: ((Result<URL, AppError>)->Void)?
        
        init(onSelection: ((Result<URL, AppError>) -> Void)?) {
            self.onSelection = onSelection
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelection: self.onSelection)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ImagePicker.Coordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imageURL = info[.imageURL] as? URL {
            self.onSelection?(.success(imageURL))
        } else {
            self.onSelection?(.failure(.message("Something went wrong")))
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Sheet Modifier
struct ImagePickerSheetModifier: ViewModifier, ImagePickerPermissionRequesting {
    
    var title: String = "Select Image"
    @Binding var isPresented: Bool
    var onResult: ((Result<URL, AppError>)->Void)?
    
    @State private var showingAlert: Bool = false
    @State private var alert: Alert!
    
    @State private var isSheetPresented: Bool = false
    
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary {
        didSet {
            self.checkPermission(for: sourceType)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .actionSheet(isPresented: $isPresented, content: {
                ActionSheet(title: Text(title), message: nil, buttons: buttons)
            })
            .sheet(isPresented: $isSheetPresented, content: {
                ImagePicker(sourceType: self.sourceType, onSelection: self.onResult)
            })
            .alert(isPresented: $showingAlert, content: {
                alert
            })
    }
    
    var buttons: [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = [.cancel()]
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            buttons.append(
                .default(Text("Camera"), action: {
                    self.sourceType = .camera
                })
            )
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            buttons.append(
                .default(Text("Photo Library"), action: {
                    self.sourceType = .photoLibrary
                })
            )
        }
        return buttons
    }
    
    private func checkPermission(for sourceType: UIImagePickerController.SourceType) {
        switch sourceType {
        case .camera:
            self.cameraAccessPermissionCheck { (success) in
                if success {
                    self.isSheetPresented.toggle()
                } else {
                    self.alert = self.alert(library: "Camera", feature: "Camera", action: "Turn on the Switch")
                    self.showingAlert.toggle()
                }
            }
        case .photoLibrary:
            self.photosAccessPermissionCheck { (success) in
                if success {
                    self.isSheetPresented.toggle()
                } else {
                    self.alert = self.alert(library: "Photos", feature: "Photo Library", action: "Select Photos")
                    self.showingAlert.toggle()
                }
            }
            
        case .savedPhotosAlbum:
            break
            
        @unknown default:
            break
        }
    }
}

extension View {
    func imagePicker(title: String = "Select Image", isPresented: Binding<Bool>, onSelection: @escaping (Result<URL, AppError>)->Void) -> some View {
        self.modifier(ImagePickerSheetModifier(title: title, isPresented: isPresented, onResult: onSelection))
    }
}

extension ImagePickerPermissionRequesting where Self: ViewModifier {
    func alert(library: String, feature: String, action: String) -> Alert {
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "App"
        let title = "\"\(appName)\" Would Like to Access the \(library)"
        let message = "Please enable \(library) access from Settings > \(appName) > \(feature) to \(action)"
        
        return Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .default(Text("Open Settings"), action: { UIApplication.shared.openSettings() }),
            secondaryButton: .cancel()
        )
    }
}

import UIKit
import AVFoundation
import Photos

protocol ImagePickerPermissionRequesting {
    func cameraAccessPermissionCheck(completion: @escaping (Bool) -> Void)
    func photosAccessPermissionCheck(completion: @escaping (Bool)->Void)
}

extension ImagePickerPermissionRequesting {
    func cameraAccessPermissionCheck(completion: @escaping (Bool) -> Void) {
        let cameraMediaType = AVMediaType.video
        let cameraAutherisationState = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        switch cameraAutherisationState {
        case .authorized:
            completion(true)
        case .denied, .notDetermined, .restricted:
            AVCaptureDevice.requestAccess(for: cameraMediaType, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
        @unknown default:
            break
        }
    }
    
    func photosAccessPermissionCheck(completion: @escaping (Bool)->Void) {
        let photosStatus = PHPhotoLibrary.authorizationStatus()
        switch photosStatus {
        case .authorized:
            completion(true)
        case .denied, .notDetermined, .restricted:
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        completion(true)
                    default:
                        completion(false)
                    }
                }
            })
        case .limited:
            completion(true)
        @unknown default:
            break
        }
    }
}

protocol ImagePickerDisplaying: ImagePickerPermissionRequesting {
    func pickerAction(sourceType : UIImagePickerController.SourceType)
    func alertForPermissionChange(forFeature feature: String, library: String, action: String)
}

extension ImagePickerPermissionRequesting where Self: UIViewController {
    func alertForPermissionChange(forFeature feature: String, library: String, action: String) {
        let settingsAction = UIAlertAction(title: "Open Settings", style: .default) { (_) in
            UIApplication.shared.openSettings()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Please enable camera access from Settings > reiwa.com > Camera to take photos
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "App"
        let alert = UIAlertController(
            title: "\"\(appName)\" Would Like to Access the \(library)",
            message: "Please enable \(library) access from Settings > \(appName) > \(feature) to \(action) photos",
            preferredStyle: .alert)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}

//extension ImagePickerDisplaying where Self: UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate {
//
//    func showMediaPickerOptions(view: UIView) {
//        let fromCameraAction = UIAlertAction(title: "Capture photo from camera", style: .default) { (_) in
//            self.pickerAction(sourceType: .camera)
//        }
//
//        let fromPhotoLibraryAction = UIAlertAction(title: "Select from photo library", style: .default) { (_) in
//            self.pickerAction(sourceType: .photoLibrary)
//        }
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            alert.addAction(fromCameraAction)
//        }
//        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
//            alert.addAction(fromPhotoLibraryAction)
//        }
//        alert.addAction(cancelAction)
//
//        self.present(alert, animated: true, completion: nil)
//    }
//
//    func pickerAction(sourceType : UIImagePickerController.SourceType) {
//        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
//            let picker = UIImagePickerController()
//            picker.sourceType = sourceType
//            picker.delegate = self
//            if sourceType == .camera {
//                self.cameraAccessPermissionCheck(completion: { (success) in
//                    if success {
//                        self.present(picker, animated: true, completion: nil)
//                    }else {
//                        self.alertForPermissionChange(forFeature: "Camera", library: "Camera", action: "take")
//                    }
//                })
//            }
//            if sourceType == .photoLibrary {
//                self.photosAccessPermissionCheck(completion: { (success) in
//                    if success {
//                        self.present(picker, animated: true, completion: nil)
//                    }else {
//                        self.alertForPermissionChange(forFeature: "Photos", library: "Photo Library", action: "select")
//                    }
//                })
//            }
//
//        }
//    }
//
//}
//
extension UIApplication {
    func openSettings() {
        let urlString = UIApplication.openSettingsURLString
        guard let url = URL(string: urlString) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
