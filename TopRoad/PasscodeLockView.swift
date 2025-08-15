import SwiftUI

struct PasscodeLockView: View {
    @Binding var isPresented: Bool
    var onUnlock: (() -> Void)?

    @State private var code: String = ""
    @State private var error: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.largeTitle)
            Text("lock_screen_title")
                .font(.title3)
            SecureField(NSLocalizedString("enter_passcode", comment: ""), text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .frame(width: 160)
                .onChange(of: code) { _, new in
                    if new.count > 4 { code = String(new.prefix(4)) }
                }
            if error {
                Text("passcode_wrong").foregroundStyle(.red).font(.footnote)
            }
            Button(NSLocalizedString("unlock", comment: "")) {
                if PasscodeManager.shared.verify(code) {
                    error = false
                    isPresented = false
                    code = ""
                    onUnlock?()
                } else {
                    error = true
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}
