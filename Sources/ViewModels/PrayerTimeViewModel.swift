import Foundation
import CoreLocation
import WidgetKit
import UserNotifications

@MainActor
public final class PrayerTimeViewModel: ObservableObject {
	@Published public private(set) var prayers: [PrayerTime] = []
	@Published public private(set) var nextPrayer: PrayerTime?
	@Published public private(set) var countdownText: String = "--:--:--"
	/// Menü çubuğu metni; `TimelineView` olmadan güncellenir (CPU tasarrufu).
	@Published public private(set) var menuBarCompactCountdown: String = "--"
	@Published public private(set) var menuBarUrgentHighlight: Bool = false

	@Published public var useAutoLocation: Bool = false {
		didSet {
			guard !suppressSettingSideEffects else { return }
			invalidateGeocodeCache()
			saveSettings()
		}
	}
	@Published public var manualCity: String = "Istanbul" {
		didSet {
			guard !suppressSettingSideEffects else { return }
			invalidateGeocodeCache()
			scheduleDebouncedSaveSettings()
		}
	}
	@Published public var manualCountry: String = "Turkey" {
		didSet {
			guard !suppressSettingSideEffects else { return }
			invalidateGeocodeCache()
			scheduleDebouncedSaveSettings()
		}
	}
	@Published public var calculationMethod: CalculationMethod = .turkey {
		didSet {
			guard !suppressSettingSideEffects else { return }
			saveSettings()
		}
	}
	@Published public var use24HourFormat: Bool = true {
		didSet {
			guard !suppressSettingSideEffects else { return }
			displayTimeFormatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
			saveSettings()
			if !prayers.isEmpty {
				updatePrayerTimeStrings()
			}
		}
	}
	@Published public var preAlertMinutes: Int? = 45 {
		didSet {
			guard !suppressSettingSideEffects else { return }
			saveSettings()
			showSuccessMessage("Ayarlar kaydedildi")
			if notificationsEnabled && !prayers.isEmpty {
				Task {
					await NotificationManager.shared.scheduleNotifications(for: rawPrayerTimes, preAlertMinutes: preAlertMinutes)
				}
			}
		}
	}
	@Published public var notificationsEnabled: Bool = true {
		didSet {
			guard !suppressSettingSideEffects else { return }
			saveSettings()
			showSuccessMessage(notificationsEnabled ? "Bildirimler etkinleştirildi" : "Bildirimler devre dışı bırakıldı")
			if notificationsEnabled && !prayers.isEmpty {
				Task {
					try? await NotificationManager.shared.requestAuthorization()
					await NotificationManager.shared.scheduleNotifications(for: rawPrayerTimes, preAlertMinutes: preAlertMinutes)
				}
			} else if !notificationsEnabled {
				Task {
					UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
				}
			}
		}
	}
	@Published public var errorMessage: String?
	@Published public var successMessage: String?
	@Published public var isLoading: Bool = false

	private let service: PrayerTimeService
	private let locationManager = LocationManager()
	private var rawPrayerTimes: [PrayerTime] = []

	private var suppressSettingSideEffects = false
	private var debouncedSaveTask: Task<Void, Never>?

	private var countdownWorkItem: DispatchWorkItem?
	private var didRunInitialStart = false

	private let displayTimeFormatter: DateFormatter = {
		let f = DateFormatter()
		f.locale = Locale(identifier: "tr_TR_POSIX")
		f.dateFormat = "HH:mm"
		return f
	}()

	/// Aladhan `meta.timezone`; gösterim ve sonraki isteklerin takvim günü için kullanılır.
	private var prayerLocationTimeZone: TimeZone = .current

	private var cachedGeocodeKey: String?
	private var cachedGeocodeCoordinate: CLLocationCoordinate2D?

	private var lastWidgetTimingsData: Data?
	private var lastWidgetTimeZoneId: String?

	public init(service: PrayerTimeService = PrayerTimeService()) {
		self.service = service
		loadSettings()
	}

	deinit {
		countdownWorkItem?.cancel()
		debouncedSaveTask?.cancel()
	}

	public func start() {
		if notificationsEnabled {
			Task {
				try? await NotificationManager.shared.requestAuthorization()
			}
		}
		if didRunInitialStart {
			scheduleCountdownLoop()
			return
		}
		didRunInitialStart = true
		Task {
			await refreshTimings(userInitiated: false)
		}
	}

	public func refreshTimings(userInitiated: Bool = false) async {
		if isLoading && !userInitiated {
			scheduleCountdownLoop()
			return
		}

		countdownWorkItem?.cancel()
		countdownWorkItem = nil

		isLoading = true
		errorMessage = nil
		do {
			let coordinate = try await resolveCoordinate()

			let todayResult = try await service.fetchPrayerDay(params: .init(
				date: Date(),
				latitude: coordinate.latitude,
				longitude: coordinate.longitude,
				method: calculationMethod.rawValue,
				civilDateTimeZone: prayerLocationTimeZone
			))
			let tz = todayResult.timeZone
			prayerLocationTimeZone = tz
			displayTimeFormatter.timeZone = tz

			let todayTimings = todayResult.timings
			var allPrayers = TimingsCodec.buildPrayerTimes(from: todayTimings, on: Date(), timeZone: tz)

			let now = Date()
			let hasUpcomingPrayer = allPrayers.contains(where: { $0.date > now })

			if !hasUpcomingPrayer {
				var cal = Calendar(identifier: .gregorian) ?? Calendar.current
				cal.timeZone = tz
				let todayStart = cal.date(from: cal.dateComponents([.year, .month, .day], from: Date())) ?? Date()
				let tomorrow = cal.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
				let tomorrowResult = try await service.fetchPrayerDay(params: .init(
					date: tomorrow,
					latitude: coordinate.latitude,
					longitude: coordinate.longitude,
					method: calculationMethod.rawValue,
					civilDateTimeZone: tz
				))

				let tomorrowPrayers = TimingsCodec.buildPrayerTimes(from: tomorrowResult.timings, on: tomorrow, timeZone: tomorrowResult.timeZone)
				if let tomorrowFajr = tomorrowPrayers.first(where: { $0.name == "İmsak" }) {
					allPrayers.append(tomorrowFajr)
				}
			}

			rawPrayerTimes = allPrayers
			updatePrayerTimeStrings()
			let computedNext = computeNextPrayer(from: prayers)
			if computedNext != nextPrayer {
				nextPrayer = computedNext
			}
			saveToSharedDefaultsIfChanged(timings: todayTimings, timeZone: tz)
			if notificationsEnabled {
				try? await NotificationManager.shared.requestAuthorization()
				await NotificationManager.shared.scheduleNotifications(for: allPrayers, preAlertMinutes: preAlertMinutes)
			}
			isLoading = false
			if userInitiated && !rawPrayerTimes.isEmpty {
				showSuccessMessage("Vakitler güncellendi")
			}
			scheduleCountdownLoop()
		} catch {
			handleError(error)
			isLoading = false
			scheduleCountdownLoop()
		}
	}

	private func handleError(_ error: Error) {
		if let serviceError = error as? PrayerTimeService.ServiceError {
			switch serviceError {
			case .invalidURL:
				errorMessage = "API adresi geçersiz. Geliştirici ayarlarını kontrol edin."
			case .network(let underlyingError):
				if let urlError = underlyingError as? URLError {
					switch urlError.code {
					case .notConnectedToInternet, .networkConnectionLost:
						errorMessage = "İnternet bağlantısı yok. Ağı kontrol edip yeniden deneyin."
					case .timedOut:
						errorMessage = "İstek zaman aşımına uğradı. Servis şu an meşgul olabilir."
					default:
						errorMessage = "Ağ hatası: \(urlError.localizedDescription)"
					}
				} else {
					errorMessage = "Ağ hatası: \(underlyingError.localizedDescription)"
				}
			case .decoding:
				errorMessage = "Namaz verisi okunamadı. API yanıtı beklenenden farklı olabilir."
			case .invalidResponse:
				errorMessage = "Sunucudan geçersiz yanıt alındı. Daha sonra tekrar deneyin."
			}
		} else if let locationError = error as? LocationManager.LocationError {
			switch locationError {
			case .denied:
				errorMessage = "Konum erişimi reddedildi. Sistem Ayarları’ndan konumu etkinleştirin."
			case .restricted:
				errorMessage = "Konum kullanımı kısıtlı. Gizlilik ayarlarını kontrol edin."
			case .unableToFindLocation:
				errorMessage = "Konum bulunamadı. Şehir ve ülke adını gözden geçirin."
			}
		} else {
			errorMessage = "Hata: \(error.localizedDescription)"
		}
	}

	private func invalidateGeocodeCache() {
		cachedGeocodeKey = nil
		cachedGeocodeCoordinate = nil
	}

	private func resolveCoordinate() async throws -> CLLocationCoordinate2D {
		if useAutoLocation {
			return try await locationManager.requestOneShotLocation()
		} else {
			let query = [manualCity, manualCountry].filter { !$0.isEmpty }.joined(separator: ", ")
			if query.isEmpty { throw LocationManager.LocationError.unableToFindLocation }
			if query == cachedGeocodeKey, let c = cachedGeocodeCoordinate {
				return c
			}
			let coord = try await geocode(query: query)
			cachedGeocodeKey = query
			cachedGeocodeCoordinate = coord
			return coord
		}
	}

	private func geocode(query: String) async throws -> CLLocationCoordinate2D {
		try await withCheckedThrowingContinuation { continuation in
			let geocoder = CLGeocoder()
			geocoder.geocodeAddressString(query) { placemarks, error in
				if let error {
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

	private func updatePrayerTimeStrings() {
		let formatter = displayTimeFormatter
		let newPrayers = rawPrayerTimes.map { prayer in
			PrayerTime(
				id: prayer.id,
				name: prayer.name,
				timeString: formatter.string(from: prayer.date),
				date: prayer.date
			)
		}
		if newPrayers != prayers {
			prayers = newPrayers
		}
	}

	private func computeNextPrayer(from list: [PrayerTime]) -> PrayerTime? {
		let now = Date()
		return list.first(where: { $0.date > now })
	}

	private func scheduleDebouncedSaveSettings() {
		debouncedSaveTask?.cancel()
		debouncedSaveTask = Task {
			try? await Task.sleep(nanoseconds: 450_000_000)
			guard !Task.isCancelled else { return }
			saveSettings()
		}
	}

	/// Kademeli gecikme: <1 saat 1 sn, 1–6 saat 10 sn, üzeri 60 sn (işlemci uyandırma sıklığını düşürür).
	private func scheduleCountdownLoop() {
		countdownWorkItem?.cancel()
		let item = DispatchWorkItem { [weak self] in
			self?.countdownTickAndReschedule()
		}
		countdownWorkItem = item
		DispatchQueue.main.async(execute: item)
	}

	private func countdownTickAndReschedule() {
		if let next = computeNextPrayer(from: prayers), next.id != nextPrayer?.id {
			nextPrayer = next
		}

		guard let target = nextPrayer?.date else {
			setCountdownDisplay(h: 0, m: 0, s: 0, showPlaceholder: true)
			scheduleNextCountdown(after: prayers.isEmpty ? 8 : 30)
			return
		}

		let remaining = max(0, Int(target.timeIntervalSinceNow))

		if remaining == 0 {
			if !isLoading {
				Task { await refreshTimings(userInitiated: false) }
			}
			scheduleNextCountdown(after: 2)
			return
		}

		let h = remaining / 3600
		let m = (remaining % 3600) / 60
		let s = remaining % 60
		setCountdownDisplay(h: h, m: m, s: s, showPlaceholder: false)
		updateMenuBarDisplay(remaining: remaining)

		let delay: TimeInterval
		if remaining < 3600 {
			delay = 1
		} else if remaining < 21600 {
			delay = 10
		} else {
			delay = 60
		}

		scheduleNextCountdown(after: delay)
	}

	private func scheduleNextCountdown(after delay: TimeInterval) {
		countdownWorkItem?.cancel()
		let nextItem = DispatchWorkItem { [weak self] in
			self?.countdownTickAndReschedule()
		}
		countdownWorkItem = nextItem
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: nextItem)
	}

	private func setCountdownDisplay(h: Int, m: Int, s: Int, showPlaceholder: Bool) {
		let newText: String
		if showPlaceholder {
			newText = "--:--:--"
			if menuBarCompactCountdown != "--" {
				menuBarCompactCountdown = "--"
			}
			if menuBarUrgentHighlight {
				menuBarUrgentHighlight = false
			}
		} else {
			newText = String(format: "%02d:%02d:%02d", h, m, s)
		}
		if newText != countdownText {
			countdownText = newText
		}
	}

	private func updateMenuBarDisplay(remaining: Int) {
		let hours = remaining / 3600
		let minutes = (remaining % 3600) / 60
		let urgent = hours == 0 && minutes > 0 && minutes < 15
		let newCompact: String
		if hours > 0 {
			newCompact = "\(hours)s \(minutes)dk"
		} else {
			newCompact = "\(minutes)dk"
		}
		if newCompact != menuBarCompactCountdown {
			menuBarCompactCountdown = newCompact
		}
		if urgent != menuBarUrgentHighlight {
			menuBarUrgentHighlight = urgent
		}
	}

	private func saveToSharedDefaultsIfChanged(timings: Timings, timeZone: TimeZone) {
		let encoder = JSONEncoder()
		guard let data = try? encoder.encode(timings) else { return }
		let tzId = timeZone.identifier
		if data == lastWidgetTimingsData, tzId == lastWidgetTimeZoneId { return }
		lastWidgetTimingsData = data
		lastWidgetTimeZoneId = tzId
		SharedDefaults.defaults?.set(data, forKey: SharedDefaults.Keys.latestTimingsJSON)
		SharedDefaults.defaults?.set(tzId, forKey: SharedDefaults.Keys.latestPrayerTimeZoneID)
		SharedDefaults.defaults?.set(Date(), forKey: SharedDefaults.Keys.latestFetchDate)
		WidgetCenter.shared.reloadAllTimelines()
	}

	private func loadSettings() {
		suppressSettingSideEffects = true
		defer { suppressSettingSideEffects = false }

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
			calculationMethod = .turkey
		}
		use24HourFormat = defaults.object(forKey: SharedDefaults.Keys.use24HourFormat) as? Bool ?? true
		displayTimeFormatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
		if let tzId = defaults.string(forKey: SharedDefaults.Keys.latestPrayerTimeZoneID),
		   let tz = TimeZone(identifier: tzId) {
			prayerLocationTimeZone = tz
			displayTimeFormatter.timeZone = tz
			lastWidgetTimeZoneId = tzId
		}
		notificationsEnabled = defaults.object(forKey: SharedDefaults.Keys.notificationsEnabled) as? Bool ?? true
		if let preAlert = defaults.object(forKey: SharedDefaults.Keys.preAlertMinutes) as? Int {
			preAlertMinutes = preAlert
		} else {
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
