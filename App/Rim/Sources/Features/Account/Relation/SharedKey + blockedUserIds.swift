//
//  SharedKey + blockedUserIds.swift
//  Rim
//
//  Created by 노우영 on 8/13/25.
//

import Foundation
import Sharing

extension SharedReaderKey where Self == InMemoryKey<Set<String>> {
  static var blockedUserIds: Self {
      inMemory("blockedUserIds")
  }
}
