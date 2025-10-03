import Foundation
import CoreLocation
import WidgetKit

@MainActor
public final class PrayerTimeViewModel: ObservableObject {
	@Published public private(set) var prayers: [PrayerTime] = []
	@Published public private(set) var nextPrayer: PrayerTime?
	@Published public private(set) var countdownText: String = "--:--:--"
	@Published public var useAutoLocation: Bool = false
	@Published public var manualCity: String = "Istanbul"
	@Published public var manualCountry: String = "Turkey"
	@Published public var preAlertMinutes: Int? = 15
	@Published public var notificationsEnabled: Bool = true
	@Published public var errorMessage: String?
	@Published public var isLoading: Bool = false

	private let service: PrayerTimeService
	private let locationManager = LocationManager()
	private var timer: Timer?

	public init(service: PrayerTimeService = PrayerTimeService()) {
		self.service = service
	}

	deinit {
		timer?.invalidate()
	}

	public func start() {
		Task { await refreshTimings() }
		startTimer()
	}

	public func refreshTimings() async {
		self.isLoading = true
		self.errorMessage = nil
		do {
			let coordinate = try await resolveCoordinate()
			print("📍 Konum: \(coordinate.latitude), \(coordinate.longitude)")
			let timings = try await service.fetchTimings(params: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))
			print("✅ Vakitler alındı: \(timings)")
			self.prayers = buildPrayerTimes(from: timings, on: Date())
			self.nextPrayer = computeNextPrayer(from: prayers)
			saveToSharedDefaults(timings: timings)
			WidgetCenter.shared.reloadAllTimelines()
			if notificationsEnabled {
				try? await NotificationManager.shared.requestAuthorization()
				await NotificationManager.shared.scheduleNotifications(for: prayers, preAlertMinutes: preAlertMinutes)
			}
			self.isLoading = false
		} catch {
			print("❌ HATA: \(error)")
			self.errorMessage = "Hata: \(error.localizedDescription)"
			self.isLoading = false
		}
	}

	private func resolveCoordinate() async throws -> CLLocationCoordinate2D {
		if useAutoLocation {
			return try await locationManager.requestOneShotLocation()
		} else {
			let query = [manualCity, manualCountry].filter { !$0.isEmpty }.joined(separator: ", ")
			if query.isEmpty { throw LocationManager.LocationError.unableToFindLocation }
			return try await geocode(query: query)
		}
	}

	private func geocode(query: String) async throws -> CLLocationCoordinate2D {
		return try await withCheckedThrowingContinuation { continuation in
			let geocoder = CLGeocoder()
			geocoder.geocodeAddressString(query) { placemarks, error in
				if let error = error {
					continuation.resume(throwing: error)
					return
				}
				if let loc = placemarks?.first?.location?.coordinate {
					continuation.resume(returning: loc)
				} else {
					continuation.resume(throwing: LocationManager.LocationError.unableToFindLocation)
				}
			}
		}
	}

	private func buildPrayerTimes(from timings: Timings, on date: Date) -> [PrayerTime] {
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
			// If computed time is in the past and corresponds to after midnight offset, keep as is
			return PrayerTime(id: name, name: name, timeString: timeStr, date: dt)
		}.sorted(by: { $0.date < $1.date })
	}

	private func computeNextPrayer(from list: [PrayerTime]) -> PrayerTime? {
		let now = Date()
		return list.first(where: { $0.date > now })
	}

	private func startTimer() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
			Task { @MainActor in
				guard let self = self else { return }
				let target = self.nextPrayer?.date ?? Date()
				let remaining = max(0, Int(target.timeIntervalSinceNow))
				let hours = remaining / 3600
				let minutes = (remaining % 3600) / 60
				let seconds = remaining % 60
				self.countdownText = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
			}
		}
	}

	private func saveToSharedDefaults(timings: Timings) {
		let encoder = JSONEncoder()
		if let data = try? encoder.encode(timings) {
			SharedDefaults.defaults?.set(data, forKey: SharedDefaults.Keys.latestTimingsJSON)
			SharedDefaults.defaults?.set(Date(), forKey: SharedDefaults.Keys.latestFetchDate)
		}
	}
}

