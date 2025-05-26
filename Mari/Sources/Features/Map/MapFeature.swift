//
//  MapFeature.swift
//  Mari
//
//  Created by 노우영 on 5/26/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct MapFeature {
    @ObservableState
    struct State {
        
    }
    
    enum Action: ViewAction {
        case view(View)
        
        enum View {
            case cameraButtonTapped
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.cameraButtonTapped):
                return .none
            }
        }
    }
}
