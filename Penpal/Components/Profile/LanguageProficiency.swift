//
//  LanguageProficiency.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/5/24.
//

import Foundation

class LanguageProficiency: Codable {
    var language: Language
    var proficiencyLevel: String
   
    
    
    init(language: Language, proficiencyLevel: String, isNative: Bool) {
        self.language = language
        self.proficiencyLevel = proficiencyLevel
    }
    
}

struct Language: String, Codable, CaseIterable {
    var id: String
    var name: String
    var languageCode: String
    static let predefinedLanguages: [Language] = [
        Language(id: "1", name: "English", languageCode: "en"),
        Language(id: "2", name: "Spanish (Spain)", languageCode: "es"),
        Language(id: "2", name: "Spanish (United States)", languageCode: "es-US"),
        Language(id: "3", name: "English", languageCode: "en"),
        Language(id: "4", name: "French", languageCode: "fr"),
        Language(id: "5", name: "Italian", languageCode: "it"),
        Language(id: "6", name: "German", languageCode: "de"),
        Language(id: "7", name: "Hindi", languageCode: "hi"),
        Language(id: "8", name: "Arabic", languageCode: "ar"),
        Language(id: "9", name: "Mandarin", languageCode: "zh-HANS"),
        Language(id: "10", name: "Portuguese (Portugal)", languageCode: "pt-PT"),
        Language(id: "10", name: "Portuguese (Brazil)", languageCode: "pt-BR"),
        Language(id: "11", name: "Japanese", languageCode: "ja"),
        Language(id: "12", name: "Korean", languageCode: "ko"),
        Language(id: "13", name: "Russian", languageCode: "ru"),
        Language(id: "14", name: "Spanish (Latin America", languageCode: "es-419"),
    ]
    
}

