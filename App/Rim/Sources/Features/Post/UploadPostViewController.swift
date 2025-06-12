//
//  UploadPostViewController.swift
//  Mari
//
//  Created by 노우영 on 6/11/25.
//

import Foundation
import UIKit
import ComposableArchitecture
import SnapKit

@Reducer
struct UploadPostFeature {
    @ObservableState
    struct State {
        let imageURL: String
    }
    
    enum Action: ViewAction {
        case view(View)
        
        enum View {
            
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view:
                return .none
            }
        }
    }
}

@ViewAction(for: UploadPostFeature.self)
class UploadPostViewController: UIViewController {
    let store: StoreOf<UploadPostFeature>
    
    init(store: StoreOf<UploadPostFeature>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
