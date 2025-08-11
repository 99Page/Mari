//
//  Shared + ToS.swift
//  Rim
//
//  Created by 노우영 on 8/11/25.
//

import Foundation
import Sharing

/// 사용자의 EULA 동의 여부를 저장
extension SharedReaderKey where Self == AppStorageKey<Bool> {
  static var hasAgreedToEULA: Self {
      appStorage("hasAgreedToEULA")
  }
}
