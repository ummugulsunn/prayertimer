// Models for Aladhan API response
import Foundation

public struct Timings: Codable, Equatable {
	public let Fajr: String
	public let Sunrise: String
	public let Dhuhr: String
	public let Asr: String
	public let Maghrib: String
	public let Isha: String
	public let Imsak: String?
	public let Sunset: String?
	public let Midnight: String?
	public let Firstthird: String?
	public let Lastthird: String?
}

/// Konumun namaz saatleri için kullandığı IANA saat dilimi (ör. `Europe/Istanbul`).
public struct PrayerTimesMeta: Codable, Equatable {
	public let timezone: String
}

public struct TimingsData: Codable, Equatable {
	public let timings: Timings
	public let meta: PrayerTimesMeta?
}

public struct APIResponse: Codable, Equatable {
	public let data: TimingsData
}

public enum PrayerName: String, CaseIterable, Codable {
	case imsak = "İmsak"
	case sunrise = "Güneş"
	case dhuhr = "Öğle"
	case asr = "İkindi"
	case maghrib = "Akşam"
	case isha = "Yatsı"
}

public struct PrayerTime: Equatable, Identifiable {
	public let id: String
	public let name: String
	public let timeString: String
	public let date: Date
}

/// Aladhan yanıtından çıkarılan vakitler + hesaplamanın geçerli olduğu saat dilimi.
public struct FetchedPrayerDay: Sendable {
	public let timings: Timings
	public let timeZone: TimeZone

	public init(timings: Timings, timeZone: TimeZone) {
		self.timings = timings
		self.timeZone = timeZone
	}
}
