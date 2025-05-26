//
//  HomeViewController.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import UIKit
import SnapKit
import AVFoundation
import FirebaseStorage
import NMapsMap

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let button = UIButton(type: .custom)
    private let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupView()
                        self.makeConstraint()
                    } else {
                        self.showCameraAccessDeniedAlert()
                    }
                }
            }
        case .authorized:
            setupView()
            makeConstraint()
        case .denied, .restricted:
            showCameraAccessDeniedAlert()
        @unknown default:
            break
        }
    }
    
    private func setupView() {
        view.backgroundColor = .white
        
        button.setTitle("Camera", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.presentCamera()
        }), for: .touchUpInside)
    }
    
    private func makeConstraint() {
        view.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(100)
        }
    }

    private func showCameraAccessDeniedAlert() {
        let alert = UIAlertController(
            title: "카메라 접근 불가",
            message: "설정에서 카메라 접근 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {

            let storageRef = Storage.storage().reference()
            let filename = "images/\(UUID().uuidString).jpg"
            let imageRef = storageRef.child(filename)

            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            imageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("❌ 업로드 실패: \(error.localizedDescription)")
                    return
                }

                imageRef.downloadURL { url, error in
                    if let url = url {
                        print("✅ 업로드 성공. 다운로드 URL: \(url.absoluteString)")
                    } else {
                        print("❌ URL 가져오기 실패")
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
