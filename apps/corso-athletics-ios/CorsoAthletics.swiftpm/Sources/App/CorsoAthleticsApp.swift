import SwiftUI

@main
struct CorsoAthleticsApp: App {
    @State private var store: AthleticsStore

    init() {
        print("Corso Athletics 0.3.0 reached app startup")
        _store = State(initialValue: AthleticsStore())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
                .environment(store)
                .tint(CorsoTheme.orange)
                .preferredColorScheme(.light)
        }
    }
}

/// Always paints a real launch surface before constructing the navigation
/// hierarchy. This makes startup visible and avoids an unexplained black
/// window while Swift Playgrounds installs a newly built pilot.
private struct AppRootView: View {
    let store: AthleticsStore
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            CorsoTheme.cream
                .ignoresSafeArea()

            if hasStarted {
                AppShell(store: store)
                    .transition(.opacity)
            } else {
                CorsoLaunchView()
                    .transition(.opacity)
            }
        }
        .task {
            // Yield one render pass so a visible screen is guaranteed before
            // the larger split-view hierarchy is installed.
            await Task.yield()
            withAnimation(.easeOut(duration: 0.2)) {
                hasStarted = true
            }
        }
    }
}

private struct CorsoLaunchView: View {
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

            Text("Starting Corso Athletics 0.3.0…")
                .font(.headline)
                .foregroundStyle(CorsoTheme.muted)

            ProgressView()
                .tint(CorsoTheme.orange)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Corso Athletics 0.3.0 is starting")
    }
}
