//
//  SharedKey + uid .swift
//  Rim
//
//  Created by 노우영 on 7/10/25.
//

import Foundation
import Sharing
import SwiftUI

extension SharedReaderKey where Self == AppStorageKey<String?> {
  static var uid: Self {
      appStorage("uid")
  }
}
