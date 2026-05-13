import Foundation

public enum TimingsCodec {
	public static func decodeFromShared() -> Timings? {
		guard let data = SharedDefaults.defaults?.data(forKey: SharedDefaults.Keys.latestTimingsJSON) else { return nil }
		return try? JSONDecoder().decode(Timings.self, from: data)
	}

	public static func timeZoneFromShared() -> TimeZone {
		guard let id = SharedDefaults.defaults?.string(forKey: SharedDefaults.Keys.latestPrayerTimeZoneID),
		      let tz = TimeZone(identifier: id) else {
			return .current
		}
		return tz
	}

	/// Aladhan `HH:mm` saatlerini `timeZone` içindeki takvim günü ile birleştirir. İmsak için `Imsak` alanı varsa onu kullanır.
	public static func buildPrayerTimes(from timings: Timings, on date: Date, timeZone: TimeZone) -> [PrayerTime] {
		var cal = Calendar(identifier: .gregorian) ?? Calendar.current
		cal.timeZone = timeZone

		let imsak = (timings.Imsak ?? timings.Fajr).trimmingCharacters(in: .whitespacesAndNewlines)

		let pairs: [(String, String)] = [
			("İmsak", imsak),
			("Güneş", timings.Sunrise.trimmingCharacters(in: .whitespacesAndNewlines)),
			("Öğle", timings.Dhuhr.trimmingCharacters(in: .whitespacesAndNewlines)),
			("İkindi", timings.Asr.trimmingCharacters(in: .whitespacesAndNewlines)),
			("Akşam", timings.Maghrib.trimmingCharacters(in: .whitespacesAndNewlines)),
			("Yatsı", timings.Isha.trimmingCharacters(in: .whitespacesAndNewlines))
		]

		let ymd = cal.dateComponents([.year, .month, .day], from: date)

		return pairs.compactMap { name, timeStr -> PrayerTime? in
			let trimmed = normalizeAladhanTimeComponent(timeStr)
			guard !trimmed.isEmpty else { return nil }

			let hmParts = trimmed.split(separator: ":")
			guard hmParts.count >= 2,
			      let h = Int(hmParts[0]),
			      let m = Int(String(hmParts[1]).prefix(2)),
			      (0...23).contains(h),
			      (0...59).contains(m) else { return nil }

			var comps = DateComponents()
			comps.year = ymd.year
			comps.month = ymd.month
			comps.day = ymd.day
			comps.hour = h
			comps.minute = m
			comps.second = 0

			guard let dt = cal.date(from: comps) else { return nil }
			return PrayerTime(id: name, name: name, timeString: trimmed, date: dt)
		}.sorted(by: { $0.date < $1.date })
	}

	/// API bazen "HH:mm" yerine sonek veya saniye döndürebilir; yalnızca saat/dakika kısmını alır.
	private static func normalizeAladhanTimeComponent(_ raw: String) -> String {
		var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
		if let paren = s.firstIndex(of: "(") {
			s = String(s[..<paren]).trimmingCharacters(in: .whitespacesAndNewlines)
		}
		if let sp = s.firstIndex(of: " ") {
			s = String(s[..<sp]).trimmingCharacters(in: .whitespacesAndNewlines)
		}
		let parts = s.split(separator: ":")
		if parts.count >= 2 {
			let h = String(parts[0])
			let m = String(parts[1].prefix(2))
			return "\(h):\(m)"
		}
		return s
	}
}
