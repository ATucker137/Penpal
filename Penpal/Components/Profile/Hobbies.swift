//
//  Hobbies.swift
//  Penpal
//
//
//  MARK: - Lessons Learned:
//  - Switched from `class` to `struct`
//      Value semantics play nicer with SwiftUI diffing and make copies cheap.
//  - Conformed to `Equatable`, `Hashable`, `Codable`, `Identifiable`, `Sendable`
//      Safer across concurrency, usable in Sets/Dictionaries, easy to encode/decode.
//  - Equality/Hashing based on `id` only
//      Names/emojis can change without breaking identity; storage keeps working.
//  - Added fast lookup helpers (`indexById`, `byId(_:)`) and lenient decoding
//      Decodes from either `{id,name,emoji}` or a bare string id `"sports"`.
//  - Added `toDict` / `fromDict` and `fromToken(_:)`
//      Keeps Firestore/SQLite mapping simple and resilient.
//  - Kept `predefinedHobbies` for backward compatibility (alias to `all`).
//

import Foundation

struct Hobbies: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    var name: String
    var emoji: String

    init(id: String, name: String, emoji: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }

    // Identity is id-only
    static func == (lhs: Hobbies, rhs: Hobbies) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: Catalog
    static let all: [Hobbies] = [
        Hobbies(id: "1",  name: "Sports",                   emoji: "🏃"),
        Hobbies(id: "2",  name: "Movies and Entertainment", emoji: "🎬"),
        Hobbies(id: "3",  name: "Food and Cooking",         emoji: "🍳"),
        Hobbies(id: "4",  name: "Reading and Writing",      emoji: "📚"),
        Hobbies(id: "5",  name: "Music",                    emoji: "🎵"),
        Hobbies(id: "6",  name: "Technology and Gaming",    emoji: "🎮"),
        Hobbies(id: "7",  name: "Art and Crafts",           emoji: "🎨"),
        Hobbies(id: "8",  name: "Outdoor Activities",       emoji: "🏞️"),
        Hobbies(id: "9",  name: "Animals and Pets",         emoji: "🐾"),
        Hobbies(id: "10", name: "Science",                  emoji: "🔬"),
        Hobbies(id: "11", name: "Fitness and Wellness",     emoji: "🧘"),
        Hobbies(id: "12", name: "Travel",                   emoji: "✈️"),
        Hobbies(id: "13", name: "Photography",              emoji: "📸")
    ]

    // Back-compat alias so existing code keeps compiling
    static let predefinedHobbies: [Hobbies] = all

    static let indexById: [String: Hobbies] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    static func byId(_ id: String) -> Hobbies? { indexById[id] }

    /// Accepts either a known id or a known name. Returns nil if unknown.
    static func fromToken(_ token: String) -> Hobbies? {
        if let match = byId(token) { return match }
        // Match by name (case-insensitive)
        return all.first { $0.name.compare(token, options: .caseInsensitive) == .orderedSame }
    }

    /// Convenience: resolve many tokens (ids or names), skipping unknowns.
    static func resolveMany(from tokens: [String]) -> [Hobbies] {
        tokens.compactMap { fromToken($0) }
    }

    // MARK: Codable (lenient)
    private enum CodingKeys: String, CodingKey { case id, name, emoji }

    init(from decoder: Decoder) throws {
        // Accept either keyed object or single string id
        if let c = try? decoder.container(keyedBy: CodingKeys.self) {
            let id = try c.decode(String.self, forKey: .id)
            let name = (try? c.decode(String.self, forKey: .name)) ?? Hobbies.byId(id)?.name ?? id
            let emoji = (try? c.decode(String.self, forKey: .emoji)) ?? Hobbies.byId(id)?.emoji ?? "•"
            self.init(id: id, name: name, emoji: emoji)
        } else {
            let single = try decoder.singleValueContainer()
            let id = try single.decode(String.self)
            if let known = Hobbies.byId(id) {
                self = known
            } else {
                self.init(id: id, name: id, emoji: "•")
            }
        }
    }

    // MARK: Dict helpers for Firestore/SQLite glue
    func toDict() -> [String: Any] {
        ["id": id, "name": name, "emoji": emoji]
    }

    static func fromDict(_ dict: [String: Any]) -> Hobbies? {
        if let id = dict["id"] as? String,
           let name = dict["name"] as? String,
           let emoji = dict["emoji"] as? String {
            return Hobbies(id: id, name: name, emoji: emoji)
        }
        if let id = dict["id"] as? String, let known = byId(id) { return known }
        if let name = dict["name"] as? String {
            return all.first { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
        }
        return nil
    }
}
