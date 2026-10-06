import Foundation

/// JSON in a string, for `RawRepresentable` conformances that `@SceneStorage` and `@AppStorage`
/// can store.
enum StateCoding {
    static func encode<Value: Encodable>(_ value: Value) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    static func decode<Value: Decodable>(_ type: Value.Type, from string: String) -> Value? {
        try? JSONDecoder().decode(type, from: Data(string.utf8))
    }
}
