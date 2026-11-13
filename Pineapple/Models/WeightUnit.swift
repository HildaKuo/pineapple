import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb

    var id: String { rawValue }

    static let poundsPerKilogram = 2.20462262

    static var localeDefault: WeightUnit {
        Locale.current.measurementSystem == .us ? .lb : .kg
    }

    /// Converts a stored kilogram value to this unit.
    func display(_ kilograms: Double) -> Double {
        self == .kg ? kilograms : kilograms * Self.poundsPerKilogram
    }

    /// Converts a value in this unit to kilograms for storage.
    func toKilograms(_ value: Double) -> Double {
        self == .kg ? value : value / Self.poundsPerKilogram
    }

    func format(_ kilograms: Double) -> String {
        "\(display(kilograms).formatted(.number.precision(.fractionLength(0...1)))) \(rawValue)"
    }
}

enum AppSettings {
    static let unitKey = "weightUnit"
    static let restKey = "restSeconds"
    static let defaultRest = 90
}

func formatDuration(_ interval: TimeInterval) -> String {
    let total = max(0, Int(interval))
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    return hours > 0
        ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
        : String(format: "%d:%02d", minutes, seconds)
}
