//
//  Debounce.swift
//  Penpal
//
//  Created by Austin William Tucker on 4/8/25.
//

import Foundation

class Debounce {
    private var workItem: DispatchWorkItem?

    func run(after delay: TimeInterval, _ block: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: block)
        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
}
