//
//  LanguageProficiency.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/5/24.
//

// MARK: - ProficiencyLevel
enum ProficiencyLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case novice = "Novice"
    case intermediate = "Intermediate"
    case upperIntermediate = "Upper Intermediate"
    case advanced = "Advanced"
    case native = "Native"

    var description: String {
        switch self {
        case .beginner:          return "Can understand and say basic greetings."
        case .novice:            return "Can have simple conversations about familiar topics."
        case .intermediate:      return "Can hold casual conversations and express basic opinions."
        case .upperIntermediate: return "Can follow normal-speed conversations and discuss opinions."
        case .advanced:          return "Comfortable discussing complex and abstract topics."
        case .native:            return "Speaks like a native in all contexts."
        }
    }
}

// MARK: - Language
struct Language: Codable, Equatable, Hashable, Identifiable {
    /// Use the BCP-47 code as the stable id by default.
    let id: String
    let name: String
    let languageCode: String

    init(id: String? = nil, name: String, languageCode: String) {
        self.languageCode = languageCode
        self.id = id ?? languageCode
        self.name = name
    }

    static let predefinedLanguages: [Language] = [
        Language(name: "English", languageCode: "en"),
        Language(name: "Spanish (Spain)", languageCode: "es-ES"),
        Language(name: "Spanish (United States)", languageCode: "es-US"),
        Language(name: "Spanish (Latin America)", languageCode: "es-419"),
        Language(name: "French", languageCode: "fr"),
        Language(name: "Italian", languageCode: "it"),
        Language(name: "German", languageCode: "de"),
        Language(name: "Hindi", languageCode: "hi"),
        Language(name: "Arabic", languageCode: "ar"),
        Language(name: "Mandarin Chinese (Simplified)", languageCode: "zh-Hans"),
        Language(name: "Mandarin Chinese (Traditional)", languageCode: "zh-Hant"),
        Language(name: "Portuguese (Portugal)", languageCode: "pt-PT"),
        Language(name: "Portuguese (Brazil)", languageCode: "pt-BR"),
        Language(name: "Japanese", languageCode: "ja"),
        Language(name: "Korean", languageCode: "ko"),
        Language(name: "Russian", languageCode: "ru")
    ]

    static func byCode(_ code: String) -> Language? {
        predefinedLanguages.first { $0.languageCode.lowercased() == code.lowercased() }
    }
}

// MARK: - LanguageProficiency
struct LanguageProficiency: Codable, Equatable {
    var language: Language
    var level: ProficiencyLevel
    var isNative: Bool

    init(language: Language, level: ProficiencyLevel, isNative: Bool) {
        self.language = language
        self.level = level
        self.isNative = isNative
    }
}

// MARK: - Firestore helpers
extension LanguageProficiency {
    /// Keeps the nested shape your service expects:
    /// { language: { id/name/code }, level: "...", isNative: Bool }
    func toDict() -> [String: Any] {
        [
            "language": [
                "id": language.id,
                "name": language.name,
                "code": language.languageCode
            ],
            "level": level.rawValue,
            "isNative": isNative
        ]
    }

    /// Parses the nested shape, with a small fallback for older flat shapes.
    static func fromDict(_ dict: [String: Any]) -> LanguageProficiency? {
        // Preferred nested shape
        if let langDict = dict["language"] as? [String: Any],
           let code = langDict["code"] as? String,
           let name = langDict["name"] as? String,
           let levelRaw = dict["level"] as? String,
           let level = ProficiencyLevel(rawValue: levelRaw) {

            let id = (langDict["id"] as? String) ?? code
            let isNative = dict["isNative"] as? Bool ?? false
            let lang = Language(id: id, name: name, languageCode: code)
            return LanguageProficiency(language: lang, level: level, isNative: isNative)
        }

        // Fallback: flat shape { languageCode, languageName, level, isNative }
        if let code = dict["languageCode"] as? String,
           let name = dict["languageName"] as? String,
           let levelRaw = dict["level"] as? String,
           let level = ProficiencyLevel(rawValue: levelRaw) {

            let isNative = dict["isNative"] as? Bool ?? false
            let lang = Language(name: name, languageCode: code)
            return LanguageProficiency(language: lang, level: level, isNative: isNative)
        }

        return nil
    }
}
