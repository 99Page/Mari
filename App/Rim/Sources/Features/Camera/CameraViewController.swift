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
        var cancelButton = RimLabel.State(text: "취소", textColor: UIColor(.white), typography: .primaryAction)
        var flipCameraButton = RimImageView.State(image: .symbol(name: "arrow.trianglehead.2.clockwise.rotate.90", fgColor: .white))
        var flashButton = RimImageView.State(image: .symbol(name: "bolt.badge.automatic.fill", fgColor: .white))
        var flashMode = Flash.auto
        
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
                state.flashMode = state.flashMode.next
                state.flashButton = .init(image: .symbol(name: state.flashMode.symbol, fgColor: .white))
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
    
    @UIBindable var store: StoreOf<CameraFeature>
    
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    private var previewContentView = UIView()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    private let cancelButton: RimLabel
    private let flipCameraButton: RimImageView
    private let captureButton = CaptureButton()
    private let flashButton: RimImageView
    
    init(store: StoreOf<CameraFeature>) {
        @UIBindable var binding = store
        self.store = store
        self.cancelButton = RimLabel(state: $binding.cancelButton)
        self.flipCameraButton = RimImageView(state: $binding.flipCameraButton)
        self.flashButton = RimImageView(state: $binding.flashButton)
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupView()
        setupLocation()
        setupEvents()
        makeConstraint()
        
        present(item: $store.scope(state: \.photoPreview, action: \.photoPreview)) { store in
            PhotoPreviewController(store: store)
        }
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
            make.height.equalTo(view.snp.height).multipliedBy(0.7)
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
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
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // Input
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input)
        else { return }
        captureSession.addInput(input)
        
        // Output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
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
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        store.photoPreview = .init(capturedPhoto: image)
        send(.photoCaptured)
    }
}

extension CameraViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
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
