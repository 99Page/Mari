//
//  CameraService.swift
//  Mari
//
//  Created by 노우영 on 6/11/25.
//

import Foundation
import UIKit

final class CameraService: NSObject {
    private weak var presenter: UIViewController?
    private var completion: ((UIImage) -> Void)?

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    func presentCamera(completion: @escaping (UIImage) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            debugPrint("❌ 카메라 사용 불가")
            return
        }

        self.completion = completion

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self

        presenter?.present(picker, animated: true)
    }
}

extension CameraService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            completion?(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
