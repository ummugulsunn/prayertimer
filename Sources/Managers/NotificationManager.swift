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
			// Ana namaz vakti bildirimi
			await scheduleNotification(
				center: center,
				id: "prayer_\(prayer.id)",
				title: "🕌 \(prayer.name) Vakti",
				body: "Namaz vakti girdi.",
				date: prayer.date
			)
			
			// Hatırlatma bildirimi (eğer ayarlanmışsa)
			if let pre = preAlertMinutes, pre > 0 {
				let preDate = prayer.date.addingTimeInterval(TimeInterval(-pre * 60))
				if preDate > Date() {
					await scheduleNotification(
						center: center,
						id: "prayer_pre_\(prayer.id)",
						title: "⏰ \(prayer.name) Hatırlatması",
						body: "\(prayer.name) vakti \(pre) dakika sonra.",
						date: preDate
					)
				}
			}
		}
	}

	@MainActor
	private func scheduleNotification(center: UNUserNotificationCenter, id: String, title: String, body: String, date: Date) async {
		guard date > Date() else { return }
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body
		content.sound = .default
		let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
		let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
		let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
		try? await center.add(request)
	}
	
	/// Test bildirimi gönderir (2 saniye sonra)
	@MainActor
	public func sendTestNotification() async throws {
		let center = UNUserNotificationCenter.current()
		
		// Önce izin kontrolü
		let settings = await center.notificationSettings()
		if settings.authorizationStatus != .authorized {
			try await requestAuthorization()
		}
		
		// Test bildirimi içeriği
		let content = UNMutableNotificationContent()
		content.title = "🧪 Test Bildirimi"
		content.body = "Namaz vakitleri bildirimleri çalışıyor!"
		content.sound = .default
		
		// 2 saniye sonra tetiklenecek
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
		let request = UNNotificationRequest(identifier: "test_notification_\(UUID().uuidString)", content: content, trigger: trigger)
		
		try await center.add(request)
	}
	
	/// Bekleyen bildirimleri listeler (test için)
	@MainActor
	public func getPendingNotifications() async -> [String] {
		let center = UNUserNotificationCenter.current()
		let requests = await center.pendingNotificationRequests()
		return requests.map { "\($0.identifier): \($0.content.title)" }
	}
}

