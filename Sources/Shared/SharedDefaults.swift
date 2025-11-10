import Foundation

public enum SharedDefaults {
	public static var suiteName: String = "group.com.ummugulsun.prayertimer"

	public static var defaults: UserDefaults? {
		UserDefaults(suiteName: suiteName)
	}

	public enum Keys {
		public static let latestTimingsJSON = "latestTimingsJSON"
		public static let latestFetchDate = "latestFetchDate"
		public static let useAutoLocation = "useAutoLocation"
		public static let manualCity = "manualCity"
		public static let manualCountry = "manualCountry"
		public static let calculationMethod = "calculationMethod"
		public static let use24HourFormat = "use24HourFormat"
		public static let notificationsEnabled = "notificationsEnabled"
		public static let preAlertMinutes = "preAlertMinutes"
	}
}

