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

public struct TimingsData: Codable, Equatable {
	public let timings: Timings
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

