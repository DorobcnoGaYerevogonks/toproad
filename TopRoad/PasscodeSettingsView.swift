import SwiftUI

struct PasscodeSettingsView: View {
    @AppStorage("lockEnabled") private var lockEnabled: Bool = false
    @State private var hasPasscode: Bool = PasscodeManager.shared.hasPasscode()
    @State private var newCode: String = ""
    @State private var confirmCode: String = ""
    @State private var showSaved = false

    var body: some View {
        Form {
            Section {
                Toggle(NSLocalizedString("app_lock_enable", comment: ""), isOn: $lockEnabled)
            } footer: {
                Text("app_lock_hint")
            }

            Section(NSLocalizedString("set_passcode", comment: "")) {
                SecureField(NSLocalizedString("new_passcode", comment: ""), text: $newCode)
                    .keyboardType(.numberPad)
                    .onChange(of: newCode) { _, new in
                        if new.count > 4 { newCode = String(new.prefix(4)) }
                    }
                SecureField(NSLocalizedString("confirm_passcode", comment: ""), text: $confirmCode)
                    .keyboardType(.numberPad)
                    .onChange(of: confirmCode) { _, new in
                        if new.count > 4 { confirmCode = String(new.prefix(4)) }
                    }
                Button(NSLocalizedString("save_passcode", comment: "")) {
                    guard newCode.count == 4, newCode == confirmCode else { return }
                    PasscodeManager.shared.setPasscode(newCode)
                    hasPasscode = true
                    newCode = ""; confirmCode = ""
                    showSaved = true
                }.disabled(newCode.count != 4 || confirmCode != newCode)
            }

            if hasPasscode {
                Section {
                    Button(role: .destructive) {
                        PasscodeManager.shared.clear()
                        hasPasscode = false
                        lockEnabled = false
                    } label: {
                        Label(NSLocalizedString("remove_passcode", comment: ""), systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(Text("app_lock_title"))
        .alert(NSLocalizedString("saved", comment: ""), isPresented: $showSaved) { Button("OK", role: .cancel) {} }
    }
}
