import Foundation
import CryptoKit

struct PasscodeManager {
    static let shared = PasscodeManager()

    private let keyEnabled = "lockEnabled"
    private let keyHash = "passcodeHash"

    func isEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: keyEnabled)
    }

    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: keyEnabled)
    }

    func hasPasscode() -> Bool {
        return (UserDefaults.standard.string(forKey: keyHash) ?? "").isEmpty == false
    }

    func setPasscode(_ code: String) {
        let hash = sha256(code)
        UserDefaults.standard.set(hash, forKey: keyHash)
    }

    func verify(_ code: String) -> Bool {
        let hash = UserDefaults.standard.string(forKey: keyHash) ?? ""
        return hash == sha256(code)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: keyHash)
        UserDefaults.standard.set(false, forKey: keyEnabled)
    }

    private func sha256(_ text: String) -> String {
        let data = Data(text.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
