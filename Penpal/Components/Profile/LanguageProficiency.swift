//
//  LanguageProficiency.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/5/24.
//

import Foundation

class LanguageProficiency: Codable {
    var language: String
    var proficiencyLevel: String
    var isNative: Bool
    
    
    init(language: String, proficiencyLevel: String, isNative: Bool) {
        self.language = language
        self.proficiencyLevel = proficiencyLevel
        self.isNative = isNative
    }
    
}
