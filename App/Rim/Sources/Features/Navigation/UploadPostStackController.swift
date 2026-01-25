//
//  UploadPostStackController.swift
//  Rim
//
//  Created by 노우영 on 7/11/25.
//

import Foundation
import ComposableArchitecture
import UIKit
import SwiftUI
import NMapsMap

@Reducer
struct UploadPostNavigationStack {
    @Reducer
    enum Path {
        
    }
    
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var root: UploadPostFeature.State
        
        init(pickedImage: UIImage, photoLocation: NMGLatLng) {
            self.root = .init(pickedImage: pickedImage, photoLocation: photoLocation)
        }
    }
    
    enum Action {
        case path(StackActionOf<Path>)
        case root(UploadPostFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.root, action: \.root) {
            UploadPostFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .path(_):
                return .none
            case .root(_):
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension UploadPostNavigationStack.Path.State: Equatable {
    
}

class UploadPostStackController: NavigationStackController {
    private var store: StoreOf<UploadPostNavigationStack>!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    convenience init(store: StoreOf<UploadPostNavigationStack>!) {
        @UIBindable var store = store
        
        self.init(path: $store.scope(state: \.path, action: \.path)) {
            UIHostingController(rootView: UploadPostView(store: store.scope(state: \.root, action: \.root)))
        } destination: { store in
            switch store.case {
            
            }
        }
        
        self.store = store
    }
}
