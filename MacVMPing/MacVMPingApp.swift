import SwiftUI
import UserNotifications

@main
struct MacVMPingApp: App {

    init() {
        // Demander la permission d'envoyer des notifications au lancement
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                print("✅ Notifications autorisées")
            } else {
                print("⚠️ Notifications refusées — activez-les dans Préférences Système")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
