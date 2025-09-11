//
//  File.swift
//  RimMacro
//
//  Created by 노우영 on 9/11/25.
//

import Foundation

extension String {
    /// aaaabbb.prefixCount(of: "a"): 4
    func prefixCount(of character: Character) -> Int {
        var count = 0
        for ch in self {
            if ch == character {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}
