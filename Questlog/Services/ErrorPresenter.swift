import Foundation
import Observation

@Observable
@MainActor
final class ErrorPresenter {
    var currentError: AppError?

    func report(_ error: AppError) {
        currentError = error
    }

    func report(title: String, error: any Error) {
        currentError = AppError(title: title, message: String(describing: error), underlying: error)
    }

    func dismiss() {
        currentError = nil
    }
}
