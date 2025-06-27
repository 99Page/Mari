//
//  TextViewController.swift
//  CoreApp
//
//  Created by 노우영 on 6/12/25.
//

import Foundation
import Core
import UIKit
import ComposableArchitecture

@Reducer
struct TextViewFeature {
    @ObservableState
    struct State: Equatable {
        var textView = RimTextView.State(text: "", placeholder: "placeholder")
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        EmptyReducer()
    }
}

class TextViewController: UIViewController {
    
    let store: StoreOf<TextViewFeature>
    let textView: RimTextView
    
    init(store: StoreOf<TextViewFeature>) {
        @UIBindable var binding = store
        self.textView = RimTextView(state: $binding.textView)
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraints()
        textView.configure()
    }
    
    private func makeConstraints() {
        view.addSubview(textView)
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}
