import Foundation

public enum TimingsCodec {
	public static func decodeFromShared() -> Timings? {
		guard let data = SharedDefaults.defaults?.data(forKey: SharedDefaults.Keys.latestTimingsJSON) else { return nil }
		return try? JSONDecoder().decode(Timings.self, from: data)
	}

	public static func buildPrayerTimes(from timings: Timings, on date: Date) -> [PrayerTime] {
		let pairs: [(String, String)] = [
			("İmsak", timings.Fajr),
			("Güneş", timings.Sunrise),
			("Öğle", timings.Dhuhr),
			("İkindi", timings.Asr),
			("Akşam", timings.Maghrib),
			("Yatsı", timings.Isha)
		]
		let calendar = Calendar.current
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "tr_TR_POSIX")
		dateFormatter.dateFormat = "HH:mm"
		return pairs.compactMap { name, timeStr in
			guard let time = dateFormatter.date(from: timeStr) else { return nil }
			let comps = calendar.dateComponents([.year, .month, .day], from: date)
			let dt = calendar.date(bySettingHour: calendar.component(.hour, from: time), minute: calendar.component(.minute, from: time), second: 0, of: calendar.date(from: comps) ?? date) ?? date
			return PrayerTime(id: name, name: name, timeString: timeStr, date: dt)
		}.sorted(by: { $0.date < $1.date })
	}
}

