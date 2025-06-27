//
//  NonceGenerator.swift
//  Rim
//
//  Created by 노우영 on 6/25/25.
//

import Foundation
import Dependencies
import DependenciesMacros
import UIKit
import FirebaseAuth
import CryptoKit

@DependencyClient
struct NonceGenerator {
    var generateNonce: (_ length: Int) -> String = { _ in "" }
    var hash: (_ origin: String) -> String = { _ in "" }
}

extension NonceGenerator: DependencyKey {   
    static var liveValue: NonceGenerator {
        NonceGenerator { length in
            precondition(length > 0)
            let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
            var result = ""
            var remainingLength = length
            
            while remainingLength > 0 {
                let randoms: [UInt8] = (0..<16).map { _ in
                    var random: UInt8 = 0
                    let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                    if errorCode != errSecSuccess {
                        fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                    }
                    return random
                }
                
                randoms.forEach { random in
                    if remainingLength == 0 {
                        return
                    }
                    
                    if random < charset.count {
                        result.append(charset[Int(random)])
                        remainingLength -= 1
                    }
                }
            }
            
            return result
        } hash: { origin in
            let inputData = Data(origin.utf8)
            let hashedData = SHA256.hash(data: inputData)
            return hashedData.compactMap { String(format: "%02x", $0) }.joined()
        }
    }
}

extension DependencyValues {
    var nonceGenerator: NonceGenerator {
        get { self[NonceGenerator.self] }
        set { self[NonceGenerator.self] = newValue }
    }
}
