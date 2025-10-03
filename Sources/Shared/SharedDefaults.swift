import Foundation

public enum SharedDefaults {
	public static var suiteName: String = "group.com.ummugulsun.prayertimer"

	public static var defaults: UserDefaults? {
		UserDefaults(suiteName: suiteName)
	}

	public enum Keys {
		public static let latestTimingsJSON = "latestTimingsJSON"
		public static let latestFetchDate = "latestFetchDate"
	}
}

