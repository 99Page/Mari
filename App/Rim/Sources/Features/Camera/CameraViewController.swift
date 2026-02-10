//
//  CameraViewController.swift
//  Rim
//
//  Created by 노우영 on 7/17/25.
//

import Foundation
import UIKit
import AVFoundation
import CoreLocation
import ComposableArchitecture
import SwiftUI
import Core

@Reducer
struct CameraFeature {
    @ObservableState
    struct State: Equatable {
        var flipCameraButton = RimImageView.ImageType.symbol(name: "arrow.trianglehead.2.clockwise.rotate.90", fgColor: .white)
        var flashButton = RimImageView.ImageType.symbol(name: "bolt.slash.fill", fgColor: .white)
        
        // 플래시가 없는 디바이스도 있으니 기본 값은 off
        var flashMode = Flash.off
        
        @Presents var photoPreview: PhotoPreviewFeature.State?
        
        enum Flash {
            case on
            case off
            case auto
            
            var symbol: String {
                switch self {
                case .on: "bolt.fill"
                case .off: "bolt.slash.fill"
                case .auto: "bolt.badge.automatic.fill"
                }
            }
            
            var next: Flash {
                switch self {
                case .on: .auto
                case .off: .on
                case .auto: .off
                }
            }
            
            var setting: AVCaptureDevice.FlashMode {
                switch self {
                case .on: .on
                case .off: .off
                case .auto: .auto
                }
            }
        }
    }
    
    enum Action: ViewAction {
        case view(View)
        case photoPreview(PresentationAction<PhotoPreviewFeature.Action>)
        case delegate(Delegate)
        
        enum View: BindableAction {
            case flashButtonTapped
            case cancelButtonTapped
            case photoCaptured
            case binding(BindingAction<State>)
        }
        
        enum Delegate {
            case photoCaptured
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.cancelButtonTapped):
                return .run { send in
                    await dismiss()
                }
                
            case .view(.flashButtonTapped):
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                let hasDeviceFlash = device?.hasFlash ?? false
                
                state.flashMode = hasDeviceFlash ? state.flashMode.next : .off
                state.flashButton = .symbol(name: state.flashMode.symbol, fgColor: .white)
                return .none
                
            case .view(.photoCaptured):
                return .send(.delegate(.photoCaptured))
                
            case .view(.binding):
                return .none
                
            case .photoPreview(.presented(.delegate(.dismissPhotoView))):
                return .run { _ in await dismiss() }
                
            case .photoPreview:
                return .none
                
            case .delegate(.photoCaptured):
                return .none
            }
        }
        .ifLet(\.$photoPreview, action: \.photoPreview) { PhotoPreviewFeature() }
    }
}

@ViewAction(for: CameraFeature.self)
final class CameraViewController: UIViewController {
    
    private var lastZoomFactor: CGFloat = 1.0
    
    // 가로 4 : 세로 5
    private let aspectRatio: CGFloat = 1.25
    
    @UIBindable var store: StoreOf<CameraFeature>
    
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    private var previewContentView = UIView()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    private let cancelButton: RimLabel
    private let flipCameraButton: RimImageView
    private let captureButton = CaptureButton()
    private let flashButton: RimImageView
    
    private let sessionQueue = DispatchQueue(label: "com.page.rim.sessionQueue")
    
    init(store: StoreOf<CameraFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.cancelButton = RimLabel()
        self.flipCameraButton = RimImageView()
        self.flashButton = RimImageView()
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkCameraPermissionAndSetup()
        setupView()
        setupEvents()
        makeConstraint()
        updateView()
        
        present(item: $store.scope(state: \.photoPreview, action: \.photoPreview)) { store in
            PhotoPreviewController(store: store)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = previewLayer {
            previewLayer.frame = previewContentView.bounds
        }
    }
    
    private func updateView() {
        cancelButton.text = .constant("취소")
        cancelButton.textColor = .constant(.white)
        cancelButton.typography = .constant(.primaryAction)
        cancelButton.updateView()
        
        flipCameraButton.image = $store.flipCameraButton
        flipCameraButton.updateView()
        
        flashButton.image = $store.flashButton
        flashButton.updateView()
    }
    
    private func setupView() {
        view.backgroundColor = .black
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        cancelButton.addAction(.touchUpInside({ [weak self] in
            self?.send(.cancelButtonTapped)
        }), animation: .none)
        
        flipCameraButton.addAction(.touchUpInside({ [weak self] in
            self?.flipCamera()
        }), animation: .none)
        
        captureButton.addAction(.touchUpInside({ [weak self] in
            self?.capturePhoto()
        }))
        
        flashButton.addAction(.touchUpInside({ [weak self] in
            self?.send(.flashButtonTapped)
        }), animation: .none)
    }
    
    private func flipCamera() {
        // 현재 입력 제거
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        captureSession.removeInput(currentInput)
        
        // 새 포지션 결정
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        
        // 새 디바이스 & 인풋 생성
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice),
              captureSession.canAddInput(newInput) else {
            return
        }
        
        captureSession.addInput(newInput)
    }
    
    private func makeConstraint() {
        view.addSubview(previewContentView)
        view.addSubview(cancelButton)
        view.addSubview(flipCameraButton)
        view.addSubview(captureButton)
        view.addSubview(flashButton)
        
        flashButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.width.height.equalTo(20)
        }
        
        previewContentView.layer.addSublayer(previewLayer)
        
        previewContentView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(previewContentView.snp.width).multipliedBy(aspectRatio)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-64)
            make.leading.equalToSuperview().offset(32)
        }
        
        flipCameraButton.snp.makeConstraints { make in
            make.bottom.equalTo(cancelButton)
            make.trailing.equalToSuperview().offset(-32)
            make.width.height.equalTo(24)
        }
        
        captureButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(cancelButton)
        }
        
        previewContentView.layoutIfNeeded()
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewContentView.bounds
    }
    
    private func setupEvents() {
        addZoomEvent()
    }
    
    private func addZoomEvent() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input)
        else { return }
        
        captureSession.addInput(input)
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        startSession()
    }
    
    private func startSession() {
        // Apple은 카메라 설정 및 세션 실행을 위해 별도의 전용 시리얼 큐를 사용하는 것을 권장합니다.
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = store.flashMode.setting
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if gesture.state == .changed {
            let minZoomFactor = device.minAvailableVideoZoomFactor
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let newZoomFactor = min(max(minZoomFactor, lastZoomFactor * gesture.scale), maxZoomFactor)
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = newZoomFactor
                device.unlockForConfiguration()
            } catch {
                print("Zoom configuration failed: \(error)")
            }
        }
        
        if gesture.state == .ended {
            lastZoomFactor = device.videoZoomFactor
        }
    }
    
    private func checkCameraPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showCameraPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionDeniedAlert()
        @unknown default:
            break
        }
    }
    
    private func showCameraPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "카메라 권한 필요",
            message: "카메라 사용을 위해 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.present(alert, animated: true)
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation(),
              let rawImage = UIImage(data: imageData) else { return }

        // 1. 이미지 물리적 회전 고정 (필수: 이걸 안 하면 가로/세로가 바뀌어서 잘림)
        let fixedImage = rawImage.fixedOrientation()
        
        // 2. "좌우는 건드리지 말고 위아래만 잘라라"
        let croppedImage = cropVerticalCenter(image: fixedImage, aspectRatio: self.aspectRatio)
        
        // 3. 결과 전달
        store.photoPreview = .init(capturedPhoto: croppedImage, aspectRatio: aspectRatio)
        send(.photoCaptured)
    }
    
    // 📸 [Final Logic] 너비 고정, 높이 크롭 (Zoom 현상 방지)
    private func cropVerticalCenter(image: UIImage, aspectRatio: CGFloat) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // 1. 너비(Width)는 원본 100%를 무조건 사용 (좌우 자르기 금지)
        let newWidth = originalWidth
        
        // 2. 목표 비율(4:5 = 1.25)에 맞춰 '새로운 높이' 계산
        // 공식: 높이 = 너비 * 1.25
        // 예: 3024 * 1.25 = 3780 (원본 4032보다 작으므로 잘라낼 수 있음)
        let newHeight = floor(originalWidth * aspectRatio)
        
        // 3. 만약 계산된 높이가 원본보다 크다면? (즉, 원본이 너무 납작한 경우)
        // 이럴 때는 어쩔 수 없이 높이를 맞추고 너비를 잘라야 하지만,
        // 아이폰 세로 사진(3:4) -> 인스타 비율(4:5)에서는 무조건 newHeight가 더 작으므로 이 로직은 안전합니다.
        
        // 4. 위아래 잘라낼 여백 계산 (중앙 정렬)
        let yOffset = floor((originalHeight - newHeight) / 2.0)
        
        // 5. 크롭 영역 설정 (x=0 이므로 좌우는 안 잘림)
        let cropRect = CGRect(x: 0, y: yOffset, width: newWidth, height: newHeight)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

extension UIImage {
    
    /// 이미지의 회전 정보(Orientation)를 실제 픽셀 데이터에 반영합니다.
    /// (CoreGraphics로 크롭하기 전에 반드시 호출해야 좌표가 맞습니다.)
    func fixedOrientation() -> UIImage {
        
        // 1. 이미 방향이 '위쪽(Up)'인 경우, 수정할 필요 없음
        if imageOrientation == .up {
            return self
        }
        
        // 2. 그래픽 컨텍스트 생성
        // size: 이미지 크기
        // false: 투명도 허용 (혹시 모를 투명 영역 보존)
        // scale: 원본 스케일 유지 (Retina 디스플레이 대응)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        // 3. 이미지를 (0,0) 좌표에 그리기
        // ⭐️ 핵심: draw 메서드는 imageOrientation을 자동으로 계산해서 정방향으로 그려줍니다.
        draw(in: CGRect(origin: .zero, size: size))
        
        // 4. 그려진 이미지를 컨텍스트로부터 가져오기
        // 이제 이 이미지는 imageOrientation이 .up 상태인 순수 정방향 이미지가 됩니다.
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 5. 컨텍스트 종료 (메모리 해제)
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}

#Preview {
    let store = Store(initialState: CameraFeature.State()) {
        CameraFeature()
    }
    
    ViewControllerPreview {
        CameraViewController(store: store)
    }
    .ignoresSafeArea()
}

