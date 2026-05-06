import Foundation

struct AppError: Error, Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let underlying: (any Error)?

    init(title: String, message: String, underlying: (any Error)? = nil) {
        self.title = title
        self.message = message
        self.underlying = underlying
    }
}

enum PersistenceError: Error {
    case saveFailed
    case fetchFailed
    case modelMissing
}
