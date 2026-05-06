import Foundation

protocol SoundService: Sendable {
    func play(_ sound: String)
}

struct NoopSoundService: SoundService {
    func play(_ sound: String) {}
}
