import SwiftUI

struct HiddenTripGateView: View {
    var onUnlock: () -> Void
    @State private var showUnlock = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash").font(.largeTitle)
            Text("hidden_gate_title").font(.headline)
            Text("hidden_gate_desc")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showUnlock = true
            } label: {
                Label(NSLocalizedString("unlock_to_view", comment: ""), systemImage: "lock.open")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
        .sheet(isPresented: $showUnlock) {
            PasscodeLockView(isPresented: $showUnlock) {
                onUnlock()
            }
        }
    }
}
