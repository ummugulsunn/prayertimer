import Foundation

public enum SharedDefaults {
	public static var suiteName: String = "group.com.ummugulsun.prayertimer"

	public static var defaults: UserDefaults? {
		UserDefaults(suiteName: suiteName)
	}

	public enum Keys {
		public static let latestTimingsJSON = "latestTimingsJSON"
		/// Aladhan `meta.timezone` (IANA), widget ve tarih birleştirme ile uyumlu.
		public static let latestPrayerTimeZoneID = "latestPrayerTimeZoneID"
		public static let latestFetchDate = "latestFetchDate"
		public static let useAutoLocation = "useAutoLocation"
		public static let manualCity = "manualCity"
		public static let manualCountry = "manualCountry"
		public static let calculationMethod = "calculationMethod"
		/// 2: `CalculationMethod` ham değerleri api.aladhan.com id ile uyumlu; öncesi tek seferlik göç uygulanır.
		public static let calculationMethodSchemaVersion = "calculationMethodSchemaVersion"
		public static let use24HourFormat = "use24HourFormat"
		public static let notificationsEnabled = "notificationsEnabled"
		public static let preAlertMinutes = "preAlertMinutes"
	}
}

