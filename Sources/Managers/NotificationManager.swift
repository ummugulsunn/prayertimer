import Foundation
import UserNotifications

public final class NotificationManager {
	public static let shared = NotificationManager()
	private init() {}

	public enum NotificationError: Error {
		case notAuthorized
	}

	public func requestAuthorization() async throws {
		let center = UNUserNotificationCenter.current()
		let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
		if !granted { throw NotificationError.notAuthorized }
	}

	public func scheduleNotifications(for prayers: [PrayerTime], preAlertMinutes: Int?) async {
		let center = UNUserNotificationCenter.current()
		center.removeAllPendingNotificationRequests()

		for prayer in prayers {
			await scheduleNotification(center: center, id: "prayer_\(prayer.id)", title: prayer.name, date: prayer.date)
			if let pre = preAlertMinutes {
				let preDate = prayer.date.addingTimeInterval(TimeInterval(-pre * 60))
				if preDate > Date() {
					await scheduleNotification(center: center, id: "prayer_pre_\(prayer.id)", title: "\(prayer.name) öncesi hatırlatma", date: preDate)
				}
			}
		}
	}

	@MainActor
	private func scheduleNotification(center: UNUserNotificationCenter, id: String, title: String, date: Date) async {
		guard date > Date() else { return }
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = "Vakit girdi."
		content.sound = .default
		let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
		let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
		let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
		try? await center.add(request)
	}
}

