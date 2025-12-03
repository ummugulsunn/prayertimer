import Foundation
import CoreLocation
import WidgetKit
import UserNotifications

@MainActor
public final class PrayerTimeViewModel: ObservableObject {
	@Published public private(set) var prayers: [PrayerTime] = []
	@Published public private(set) var nextPrayer: PrayerTime?
	@Published public private(set) var countdownText: String = "--:--:--"
	@Published public var useAutoLocation: Bool = false {
		didSet { saveSettings() }
	}
	@Published public var manualCity: String = "Istanbul" {
		didSet { saveSettings() }
	}
	@Published public var manualCountry: String = "Turkey" {
		didSet { saveSettings() }
	}
	@Published public var calculationMethod: CalculationMethod = .turkey {
		didSet { saveSettings() }
	}
	@Published public var use24HourFormat: Bool = true {
		didSet { 
			saveSettings()
			// Refresh display times when format changes
			if !prayers.isEmpty {
				updatePrayerTimeStrings()
			}
		}
	}
	@Published public var preAlertMinutes: Int? = 45 {
		didSet { 
			saveSettings()
			showSuccessMessage("Ayarlar kaydedildi")
			// Ayarlar değiştiğinde bildirimleri yeniden zamanla
			if notificationsEnabled && !prayers.isEmpty {
				Task {
					await NotificationManager.shared.scheduleNotifications(for: rawPrayerTimes, preAlertMinutes: preAlertMinutes)
				}
			}
		}
	}
	@Published public var notificationsEnabled: Bool = true {
		didSet { 
			saveSettings()
			showSuccessMessage(notificationsEnabled ? "Bildirimler etkinleştirildi" : "Bildirimler devre dışı bırakıldı")
			// Bildirimler açıldığında/kapatıldığında bildirimleri güncelle
			if notificationsEnabled && !prayers.isEmpty {
				Task {
					try? await NotificationManager.shared.requestAuthorization()
					await NotificationManager.shared.scheduleNotifications(for: rawPrayerTimes, preAlertMinutes: preAlertMinutes)
				}
			} else if !notificationsEnabled {
				// Bildirimler kapatıldığında tüm bildirimleri iptal et
				Task {
					let center = UNUserNotificationCenter.current()
					center.removeAllPendingNotificationRequests()
				}
			}
		}
	}
	@Published public var errorMessage: String?
	@Published public var successMessage: String?
	@Published public var isLoading: Bool = false

	private let service: PrayerTimeService
	private let locationManager = LocationManager()
	private var timer: Timer?
	private var rawPrayerTimes: [PrayerTime] = [] // Store times with raw dates

	public init(service: PrayerTimeService = PrayerTimeService()) {
		self.service = service
		loadSettings()
	}

	deinit {
		timer?.invalidate()
	}

	public func start() {
		// Bildirim izni iste (eğer bildirimler etkinse)
		if notificationsEnabled {
			Task {
				try? await NotificationManager.shared.requestAuthorization()
			}
		}
		Task { await refreshTimings() }
		startTimer()
	}

	public func refreshTimings() async {
		self.isLoading = true
		self.errorMessage = nil
		do {
			let coordinate = try await resolveCoordinate()
			
			// Bugünün vakitlerini çek
			let todayTimings = try await service.fetchTimings(params: .init(
				date: Date(),
				latitude: coordinate.latitude,
				longitude: coordinate.longitude,
				method: calculationMethod.rawValue
			))
			
			var allPrayers = buildPrayerTimes(from: todayTimings, on: Date())
			
			// Eğer bugünün tüm vakitleri geçmişse, yarının imsak saatini ekle
			let now = Date()
			let hasUpcomingPrayer = allPrayers.contains(where: { $0.date > now })
			
			if !hasUpcomingPrayer {
				// Yarının vakitlerini çek
				let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
				let tomorrowTimings = try await service.fetchTimings(params: .init(
					date: tomorrow,
					latitude: coordinate.latitude,
					longitude: coordinate.longitude,
					method: calculationMethod.rawValue
				))
				
				// Sadece yarının İmsak saatini ekle
				let tomorrowPrayers = buildPrayerTimes(from: tomorrowTimings, on: tomorrow)
				if let tomorrowFajr = tomorrowPrayers.first(where: { $0.name == "İmsak" }) {
					allPrayers.append(tomorrowFajr)
				}
			}
			
			self.rawPrayerTimes = allPrayers
			updatePrayerTimeStrings()
			self.nextPrayer = computeNextPrayer(from: self.prayers)
			saveToSharedDefaults(timings: todayTimings)
			WidgetCenter.shared.reloadAllTimelines()
			if notificationsEnabled {
				try? await NotificationManager.shared.requestAuthorization()
				await NotificationManager.shared.scheduleNotifications(for: allPrayers, preAlertMinutes: preAlertMinutes)
			}
			self.isLoading = false
			// Sadece manuel yenileme yapıldığında başarı mesajı göster
			if !rawPrayerTimes.isEmpty {
				showSuccessMessage("Vakitler güncellendi")
			}
		} catch {
			handleError(error)
			self.isLoading = false
		}
	}
	
	private func handleError(_ error: Error) {
		if let serviceError = error as? PrayerTimeService.ServiceError {
			switch serviceError {
			case .invalidURL:
				self.errorMessage = "Invalid API URL. Please check your settings."
			case .network(let underlyingError):
				if let urlError = underlyingError as? URLError {
					switch urlError.code {
					case .notConnectedToInternet, .networkConnectionLost:
						self.errorMessage = "No internet connection. Please check your network and try again."
					case .timedOut:
						self.errorMessage = "Request timed out. The prayer time service may be unavailable."
					default:
						self.errorMessage = "Network error: \(urlError.localizedDescription)"
					}
				} else {
					self.errorMessage = "Network error: \(underlyingError.localizedDescription)"
				}
			case .decoding(_):
				self.errorMessage = "Failed to parse prayer times. The API response format may have changed."
			case .invalidResponse:
				self.errorMessage = "Invalid response from prayer time service. Please try again later."
			}
		} else if let locationError = error as? LocationManager.LocationError {
			switch locationError {
			case .denied:
				self.errorMessage = "Location access denied. Please enable location services in System Settings."
			case .restricted:
				self.errorMessage = "Location access restricted. Please check your privacy settings."
			case .unableToFindLocation:
				self.errorMessage = "Unable to find location. Please check your city and country names."
			}
		} else {
			self.errorMessage = "Error: \(error.localizedDescription)"
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
			// Store with original time string - we'll format it based on user preference
			return PrayerTime(id: name, name: name, timeString: timeStr, date: dt)
		}.sorted(by: { $0.date < $1.date })
	}
	
	private func updatePrayerTimeStrings() {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "tr_TR_POSIX")
		formatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
		
		self.prayers = rawPrayerTimes.map { prayer in
			PrayerTime(
				id: prayer.id,
				name: prayer.name,
				timeString: formatter.string(from: prayer.date),
				date: prayer.date
			)
		}
	}

	private func computeNextPrayer(from list: [PrayerTime]) -> PrayerTime? {
		let now = Date()
		return list.first(where: { $0.date > now })
	}

	private var lastUIUpdateTime: Date = Date()
	
	private func startTimer() {
		timer?.invalidate()
		lastUIUpdateTime = Date()
		
		// Timer runs every second, but UI updates adaptively for energy efficiency:
		// - < 1 hour: update UI every second (accurate countdown)
		// - < 6 hours: update UI every 10 seconds
		// - >= 6 hours: update UI every 60 seconds
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
			Task { @MainActor in
				guard let self = self else {
					timer.invalidate()
					return
				}
				
				// Recompute next prayer in case it changed
				if let next = self.computeNextPrayer(from: self.prayers), next.id != self.nextPrayer?.id {
					self.nextPrayer = next
					self.lastUIUpdateTime = Date() // Reset update time when prayer changes
				}
				
				guard let target = self.nextPrayer?.date else {
					self.countdownText = "--:--:--"
					return
				}
				
				let remaining = max(0, Int(target.timeIntervalSinceNow))
				
				// If prayer time has passed, refresh timings
				if remaining == 0 {
					Task { await self.refreshTimings() }
					return
				}
				
				// Determine update interval based on remaining time
				let hours = remaining / 3600
				let updateInterval: TimeInterval
				if hours < 1 {
					updateInterval = 1.0 // Update every second when < 1 hour
				} else if hours < 6 {
					updateInterval = 10.0 // Update every 10 seconds when < 6 hours
				} else {
					updateInterval = 60.0 // Update every minute when >= 6 hours
				}
				
				// Only update UI if enough time has passed (for energy efficiency)
				let timeSinceLastUpdate = Date().timeIntervalSince(self.lastUIUpdateTime)
				if timeSinceLastUpdate >= updateInterval {
					let hours = remaining / 3600
					let minutes = (remaining % 3600) / 60
					let seconds = remaining % 60
					self.countdownText = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
					self.lastUIUpdateTime = Date()
				}
			}
		}
		
		// Add timer to RunLoop to ensure it works properly and survives app nap
		RunLoop.main.add(timer!, forMode: .common)
		RunLoop.main.add(timer!, forMode: .eventTracking)
	}

	private func saveToSharedDefaults(timings: Timings) {
		let encoder = JSONEncoder()
		if let data = try? encoder.encode(timings) {
			SharedDefaults.defaults?.set(data, forKey: SharedDefaults.Keys.latestTimingsJSON)
			SharedDefaults.defaults?.set(Date(), forKey: SharedDefaults.Keys.latestFetchDate)
		}
	}
	
	private func loadSettings() {
		guard let defaults = SharedDefaults.defaults else { return }
		
		useAutoLocation = defaults.bool(forKey: SharedDefaults.Keys.useAutoLocation)
		if let city = defaults.string(forKey: SharedDefaults.Keys.manualCity), !city.isEmpty {
			manualCity = city
		}
		if let country = defaults.string(forKey: SharedDefaults.Keys.manualCountry), !country.isEmpty {
			manualCountry = country
		}
		if let methodRaw = defaults.object(forKey: SharedDefaults.Keys.calculationMethod) as? Int,
		   let method = CalculationMethod(rawValue: methodRaw) {
			calculationMethod = method
		} else {
			// İlk kurulumda varsayılan olarak Türkiye Diyanet yöntemini kullan
			calculationMethod = .turkey
		}
		use24HourFormat = defaults.object(forKey: SharedDefaults.Keys.use24HourFormat) as? Bool ?? true
		notificationsEnabled = defaults.object(forKey: SharedDefaults.Keys.notificationsEnabled) as? Bool ?? true
		if let preAlert = defaults.object(forKey: SharedDefaults.Keys.preAlertMinutes) as? Int {
			preAlertMinutes = preAlert
		} else {
			// İlk kurulumda varsayılan 45 dakika
			preAlertMinutes = 45
		}
	}
	
	private func saveSettings() {
		guard let defaults = SharedDefaults.defaults else { return }
		
		defaults.set(useAutoLocation, forKey: SharedDefaults.Keys.useAutoLocation)
		defaults.set(manualCity, forKey: SharedDefaults.Keys.manualCity)
		defaults.set(manualCountry, forKey: SharedDefaults.Keys.manualCountry)
		defaults.set(calculationMethod.rawValue, forKey: SharedDefaults.Keys.calculationMethod)
		defaults.set(use24HourFormat, forKey: SharedDefaults.Keys.use24HourFormat)
		defaults.set(notificationsEnabled, forKey: SharedDefaults.Keys.notificationsEnabled)
		if let preAlert = preAlertMinutes {
			defaults.set(preAlert, forKey: SharedDefaults.Keys.preAlertMinutes)
		} else {
			defaults.removeObject(forKey: SharedDefaults.Keys.preAlertMinutes)
		}
	}
	
	private func showSuccessMessage(_ message: String) {
		successMessage = message
		errorMessage = nil
		// 2 saniye sonra mesajı temizle
		Task {
			try? await Task.sleep(nanoseconds: 2_000_000_000)
			await MainActor.run {
				if successMessage == message {
					successMessage = nil
				}
			}
		}
	}
}

