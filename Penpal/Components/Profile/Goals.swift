//
//  Goals.swift
//  Penpal
//
//  Created by Austin William Tucker on 8/7/25.
//
//  - MARK: - Lessons Learned -
//  - Added `import Foundation`
//      Needed for `[String: Any]` used in `toDict`/`fromDict` helpers.
//  - Conformed `Goals` to `Equatable`, `Hashable`, and `Sendable`
//      Makes the type safer to use in sets/dicts, SwiftUI diffing, and across concurrency boundaries.
//  - Added `indexById` and convenience `byId(_:)`
//      O(1) lookups by id; avoids repeatedly scanning `Goals.all`.
//  - Made `Codable` decoding lenient
//      Supports both dictionary payloads `{id,title}` and bare string ids `"exam"` for
//      backward compatibility with older stored data (Firestore/SQLite).
//  - Custom `encode(to:)` implementation
//      Keeps serialized shape stable as `{id,title}`.
//  - Extended `fromDict(_:)`
//      Accepts `{id,title}` and also `{goalId: ...}` to be resilient to different server payloads.
//  - Kept public API and `Goals.all` intact
//      Drop-in replacement with stronger compatibility and ergonomics.
import Foundation

struct Goals: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    
    static let all: [Goals] = [
        Goals(id: "travel", title: "Have conversations while traveling"),
        Goals(id: "friends", title: "Make friends who speak the language"),
        Goals(id: "exam", title: "Prepare for language exams"),
        Goals(id: "media", title: "Understand movies, music, and books"),
        Goals(id: "pronunciation", title: "Improve pronunciation"),
        Goals(id: "writing", title: "Get better at writing"),
        Goals(id: "speaking", title: "Practice casual speaking"),
        Goals(id: "move", title: "Prepare to move abroad"),
        Goals(id: "work", title: "Learn for work or career"),
        Goals(id: "family", title: "Talk with family or partner"),
        Goals(id: "maintain", title: "Maintain language skills"),
        Goals(id: "beginner", title: "Just starting out, exploring"),
        Goals(id: "fluent", title: "Become fluent")
    ]
    
    // Fast lookup by id
    static let indexById: [String: Goals] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    static func byId(_ id: String) -> Goals? {
        indexById[id]
    }
    // Codable: be lenient on decode (accept either a dict or a raw string id)
    private enum CodingKeys: String, CodingKey { case id, title }

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    init(from decoder: Decoder) throws {
        // Try keyed container first
        if let c = try? decoder.container(keyedBy: CodingKeys.self) {
            let id = try c.decode(String.self, forKey: .id)
            let title = (try? c.decode(String.self, forKey: .title)) ?? Goals.byId(id)?.title ?? id
            self.init(id: id, title: title)
            return
        }
        // Fallback: single string (e.g., "exam")
        let single = try decoder.singleValueContainer()
        let id = try single.decode(String.self)
        if let known = Goals.byId(id) {
            self = known
        } else {
            self.init(id: id, title: id)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
    }

}

extension Goals {
    func toDict() -> [String: Any] {
            ["id": id, "title": title]
        }

    static func fromDict(_ dict: [String: Any]) -> Goals? {
        if let id = dict["id"] as? String, let title = dict["title"] as? String {
            return Goals(id: id, title: title)
        }
        // Also accept a bare id under common keys
        if let id = dict["id"] as? String, let known = Goals.byId(id) {
            return known
        }
        if let id = dict["goalId"] as? String, let known = Goals.byId(id) {
            return known
        }
        return nil
    }

}
