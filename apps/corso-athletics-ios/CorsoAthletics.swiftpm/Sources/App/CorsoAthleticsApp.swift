import SwiftUI

@main
struct CorsoAthleticsApp: App {
    var body: some Scene {
        WindowGroup {
            CorsoBootstrapView()
                .tint(CorsoTheme.orange)
                .preferredColorScheme(.light)
        }
    }
}

/// Keeps the first render as small as the known-good 0.2.0 launch path.
/// Persistence and the expanded feature hierarchy are created only after
/// Swift Playgrounds has presented a visible scene on the physical iPad.
private struct CorsoBootstrapView: View {
    private enum Phase: Equatable {
        case presentingLaunch
        case loadingWorkspace
        case running
    }

    @State private var phase: Phase = .presentingLaunch
    @State private var store: AthleticsStore?

    var body: some View {
        ZStack {
            CorsoTheme.cream
                .ignoresSafeArea()

            switch phase {
            case .presentingLaunch:
                CorsoLaunchView(status: "Preparing the iPad workspace…")
            case .loadingWorkspace:
                CorsoLaunchView(status: "Loading saved athletics data…")
            case .running:
                if let store {
                    AppShell(store: store)
                        .environment(store)
                } else {
                    CorsoLaunchView(status: "Finishing setup…")
                }
            }
        }
        .task {
            guard phase == .presentingLaunch else { return }

            // A real delay, rather than a single yield, guarantees Playgrounds
            // can commit the lightweight launch scene before model migration
            // or the expanded navigation hierarchy is constructed.
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }

            phase = .loadingWorkspace
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            store = AthleticsStore()
            await Task.yield()
            phase = .running
        }
    }
}

private struct CorsoLaunchView: View {
    let status: String

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(CorsoTheme.navy)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CorsoTheme.orange, lineWidth: 6)
                    .padding(8)
                Text("C")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 116, height: 128)

            Text("CORSO ATHLETICS")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(CorsoTheme.navy)

            Text(status)
                .font(.headline)
                .foregroundStyle(CorsoTheme.muted)

            ProgressView()
                .tint(CorsoTheme.orange)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Corso Athletics 0.4.0. \(status)")
    }
}
