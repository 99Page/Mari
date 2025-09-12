//
//  PaulHeckels.swift
//  Core
//
//  Created by 노우영 on 9/10/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation

struct PaulHeckel<Element: Identifiable & Equatable> {
    enum Operation: Equatable {
        case insert(to: Int)
        case delete(from: Int)
        case move(from: Int, to: Int)
        case update(from: Int, to: Int)
    }
    
    static var matchNone: Int { -1 }
    
    /// 두 시퀀스의 차이를 계산한다.
    /// - Parameters:
    ///   - old: 이전 시퀀스
    ///   - new: 새 시퀀스
    ///   - id: 항목의 동일성과 내용 비교를 위한 식별자
    /// - Returns: 삽입/삭제/이동/업데이트 연산 리스트 (적용은 상위 레이어에서 수행)
    static func computeDiff(from old: [Element], to new: [Element]) -> [Operation] {
        // 테이블 생성: 키별 발생 빈도와 인덱스 목록 수집
        let symbol = buildSymbolTable(old: old, new: new)
        
        var oldToNewIndex = Array(repeating: matchNone, count: old.count)
        var newToOldIndex = Array(repeating: matchNone, count: new.count)
        
        // 새 배열에서 한 번만 등장하는 키를 기준으로 동일 위치 매칭
        findUniqueMatches(old: old, new: new, symbol: symbol, oldLabels: &oldToNewIndex, newLabels: &newToOldIndex)
        
        // 4) 전파 매칭(좌→우): 인접한 동일 키를 연쇄적으로 매칭
        propagateMatchesForward(old: old, new: new, oldLabels: &oldToNewIndex, newLabels: &newToOldIndex)
        // 5) 전파 매칭(우→좌)
        propagateMatchesBackward(old: old, new: new, oldLabels: &oldToNewIndex, newLabels: &newToOldIndex)
        
        // 6) 연산 방출: 삭제, 삽입, 이동, 업데이트 순으로 계산
        return emitOperations(old: old, new: new, oldLabels: oldToNewIndex, newLabels: newToOldIndex)
    }
    
    // MARK: - 내부 구현 (Heckel 절차)
    
    /// 심볼(키)별 발생 정보를 담는 테이블 항목
    /// - countOld/new: 각 시퀀스에서의 등장 횟수
    /// - oldIndices/newIndices: 각 시퀀스 내 등장 위치 목록
    private struct SymbolEntry {
        var countOld: Int = 0
        var countNew: Int = 0
        var oldIndices: [Int] = []
        var newIndices: [Int] = []
    }
    
    /// 심볼 테이블을 구축한다.
    /// - Note: 키 기반으로 두 시퀀스의 분포를 수집하여 고유 항목(빈도 1)을 빠르게 식별
    private static func buildSymbolTable(old: [Element], new: [Element]) -> [AnyHashable: SymbolEntry] {
        var table: [AnyHashable: SymbolEntry] = [:]
        
        for (index, oldItem) in old.enumerated() {
            let k = oldItem.id
            var entry = table[k] ?? SymbolEntry()
            entry.countOld += 1
            entry.oldIndices.append(index)
            table[k] = entry
        }
        
        for (index, newItem) in new.enumerated() {
            let k = newItem.id
            var entry = table[k] ?? SymbolEntry()
            entry.countNew += 1
            entry.newIndices.append(index)
            table[k] = entry
        }
        
        return table
    }
    
    /// 양쪽 배열에서 1회만 등장하는 아이템을 찾아 매칭 시킨다.
    private static func findUniqueMatches(old: [Element], new: [Element], symbol: [AnyHashable: SymbolEntry], oldLabels: inout [Int], newLabels: inout [Int]) {
        for (_, entry) in symbol {
            guard entry.countNew == 1, entry.countOld >= 1, let newIndex = entry.newIndices.first else { continue }
            
            // 같은 키가 old에도 1개 이상 있으면, 가장 앞의 것을 우선 매칭
            guard let oldIndex = entry.oldIndices.first else { continue }
            oldLabels[oldIndex] = newIndex
            newLabels[newIndex] = oldIndex
        }
    }
    
    /// 좌→우 전파 매칭: 이전 위치가 매칭되었으면 그 다음 인접 요소도 같은 키라면 매칭한다.
    private static func propagateMatchesForward(old: [Element], new: [Element], oldLabels: inout [Int], newLabels: inout [Int]) {
        
        var i = 0 // oldArrayIndex
        var j = 0 // newArrayIndex
        
        
        while i < old.count && j < new.count { // 양쪽 배열 모두 순회
            // 이미 매칭된 페어를 찾는다
            while i < old.count && oldLabels[i] == -1 { // old에서 매칭된 것이 없다면
                i += 1
            }
            
            if i >= old.count { break }
            j = oldLabels[i]
            // 인접 전파
            var ii = i + 1
            var jj = j + 1
            while ii < old.count, jj < new.count, oldLabels[ii] == -1, newLabels[jj] == -1, old[ii].id == new[jj].id {
                oldLabels[ii] = jj
                newLabels[jj] = ii
                ii += 1
                jj += 1
            }
            i = ii
        }
    }
    
    /// 우→좌 전파 매칭: 뒤에서 앞으로 동일 키를 전파 매칭한다.
    private static func propagateMatchesBackward(old: [Element], new: [Element], oldLabels: inout [Int], newLabels: inout [Int]) {
        var i = old.count - 1
        var j = new.count - 1
        while i >= 0 && j >= 0 {
            // 이미 매칭된 페어를 찾는다
            while i >= 0 && oldLabels[i] == -1 { i -= 1 }
            if i < 0 { break }
            j = oldLabels[i]
            // 인접 전파(역방향)
            var ii = i - 1
            var jj = j - 1
            while ii >= 0, jj >= 0, oldLabels[ii] == -1, newLabels[jj] == -1, old[ii].id == new[jj].id {
                oldLabels[ii] = jj
                newLabels[jj] = ii
                ii -= 1
                jj -= 1
            }
            i = ii
        }
    }
    
    /// 매칭 결과를 기반으로 연산을 생성한다.
    /// - Note: 기본 규칙
    ///   1) 새 배열에만 있는 인덱스 → insert
    ///   2) 이전 배열에만 있는 인덱스 → delete
    ///   3) 키는 같으나 위치가 달라짐 → move
    ///   4) 키는 같고 위치도 고정되었으나 내용이 다름 → update
    private static func emitOperations(old: [Element], new: [Element], oldLabels: [Int], newLabels: [Int]) -> [Operation] {
        var ops: [Operation] = []
        
        // 삭제: 매칭 실패한 이전 인덱스들
        var isDeletedOldIndex = Array(repeating: false, count: old.count)
        for (i, mapped) in oldLabels.enumerated() where mapped == -1 {
            isDeletedOldIndex[i] = true
            ops.append(.delete(from: i))
        }
        
        
        var isInsertedNewIndex = Array(repeating: false, count: new.count)
        for (j, mapped) in newLabels.enumerated() where mapped == -1 {
            isInsertedNewIndex[j] = true
            ops.append(.insert(to: j))
        }
        
        var delPrefixOld = Array(repeating: 0, count: old.count + 1)
        for i in 0..<old.count {
            delPrefixOld[i + 1] = delPrefixOld[i] + (isDeletedOldIndex[i] ? 1 : 0)
        }
        
        var insPrefixNew = Array(repeating: 0, count: new.count + 1)
          for j in 0..<new.count {
              insPrefixNew[j + 1] = insPrefixNew[j] + (isInsertedNewIndex[j] ? 1 : 0)
          }
        
        // 이동/업데이트: 매칭된 페어들 검사
        for (i, j) in oldLabels.enumerated().compactMap({ $0.element >= 0 ? ($0.offset, Int($0.element)) : nil }) {
            let iAfterDeletes = i - delPrefixOld[i]
            let jWithoutInserts = j - insPrefixNew[j]
            
            if iAfterDeletes != jWithoutInserts {
                ops.append(.move(from: i, to: j))
            }
            // 동일 키이므로 equals로 내용 변경 확인
            if old[i] != new[j] {
                ops.append(.update(from: i, to: j))
            }
        }
        
        // 적용 편의상: 삭제는 인덱스 역순, 삽입/이동/업데이트는 인덱스 순으로 정렬
        // (테이블/컬렉션 뷰 적용 시 일반적인 안전 순서)
        ops.sort { a, b in
            switch (a, b) {
            case (.delete(let i1), .delete(let i2)):
                return i1 > i2 // 삭제는 뒤에서부터
            case (.delete, _):
                return true
            case (_, .delete):
                return false
            default:
                return String(describing: a) < String(describing: b)
            }
        }
        return ops
    }
}
