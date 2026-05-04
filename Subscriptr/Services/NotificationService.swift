import UserNotifications
import SwiftData

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleAll(for subscriptions: [Subscription]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        await center.removeAllPendingNotificationRequests()

        for subscription in subscriptions where subscription.isActive {
            await scheduleReminders(for: subscription, center: center)
        }
    }

    private func scheduleReminders(for subscription: Subscription, center: UNUserNotificationCenter) async {
        guard let renewal = subscription.nextRenewalDate else { return }

        let reminders: [(daysBefore: Int, title: String)] = [
            (3, "Renewing in 3 days"),
            (1, "Renewing tomorrow"),
        ]

        let calendar = Calendar.current
        for reminder in reminders {
            guard let fireDate = calendar.date(byAdding: .day, value: -reminder.daysBefore, to: renewal),
                  fireDate > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = subscription.name
            content.body = "\(reminder.title) — \(formatAmount(subscription.amount, cycle: subscription.billingCycle))"
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "\(subscription.persistentModelID)-\(reminder.daysBefore)d"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            try? await center.add(request)
        }
    }

    func removeReminders(for subscription: Subscription) {
        let ids = [3, 1].map { "\(subscription.persistentModelID)-\($0)d" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func formatAmount(_ amount: Double, cycle: BillingCycle) -> String {
        let formatted = amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
        return "\(formatted)/\(cycle.rawValue.lowercased())"
    }
}
