import Foundation

public final class PrayerTimeService {
	public enum ServiceError: Error {
		case invalidURL
		case network(Error)
		case decoding(Error)
		case invalidResponse
	}

	private static let session: URLSession = {
		let config = URLSessionConfiguration.ephemeral
		config.urlCache = nil
		config.requestCachePolicy = .reloadIgnoringLocalCacheData
		config.httpMaximumConnectionsPerHost = 1
		config.timeoutIntervalForRequest = 20
		config.timeoutIntervalForResource = 30
		config.waitsForConnectivity = false
		return URLSession(configuration: config)
	}()

	public init() {}

	public struct FetchParams {
		public let date: Date
		public let latitude: Double
		public let longitude: Double
		public let method: Int?
		/// API `date=DD-MM-YYYY` için hangi takvim günü kullanılacak (konum saat dilimi önerilir).
		public let civilDateTimeZone: TimeZone

		public init(
			date: Date = Date(),
			latitude: Double,
			longitude: Double,
			method: Int? = nil,
			civilDateTimeZone: TimeZone = .current
		) {
			self.date = date
			self.latitude = latitude
			self.longitude = longitude
			self.method = method
			self.civilDateTimeZone = civilDateTimeZone
		}
	}

	public func fetchPrayerDay(params: FetchParams) async throws -> FetchedPrayerDay {
		var components = URLComponents(string: "https://api.aladhan.com/v1/timings")
		var cal = Calendar(identifier: .gregorian) ?? Calendar.current
		cal.timeZone = params.civilDateTimeZone
		let day = cal.component(.day, from: params.date)
		let month = cal.component(.month, from: params.date)
		let year = cal.component(.year, from: params.date)
		let dateString = String(format: "%02d-%02d-%04d", day, month, year)
		components?.queryItems = [
			URLQueryItem(name: "date", value: dateString),
			URLQueryItem(name: "latitude", value: String(params.latitude)),
			URLQueryItem(name: "longitude", value: String(params.longitude))
		]
		if let method = params.method {
			components?.queryItems?.append(URLQueryItem(name: "method", value: String(method)))
		}
		guard let url = components?.url else { throw ServiceError.invalidURL }

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.timeoutInterval = 20

		do {
			let (data, response) = try await Self.session.data(for: request)
			guard let http = response as? HTTPURLResponse else {
				throw ServiceError.invalidResponse
			}

			guard (200..<300).contains(http.statusCode) else {
				let statusCode = http.statusCode
				if statusCode == 400 {
					throw ServiceError.invalidResponse
				} else if statusCode == 429 {
					throw ServiceError.network(NSError(domain: "PrayerTimeService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Too many requests. Please try again later."]))
				} else if statusCode >= 500 {
					throw ServiceError.network(NSError(domain: "PrayerTimeService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Prayer time service is temporarily unavailable. Please try again later."]))
				} else {
					throw ServiceError.invalidResponse
				}
			}

			let decoder = JSONDecoder()
			let api = try decoder.decode(APIResponse.self, from: data)
			let tz: TimeZone
			if let id = api.data.meta?.timezone,
			   let resolved = TimeZone(identifier: id) {
				tz = resolved
			} else {
				tz = params.civilDateTimeZone
			}
			return FetchedPrayerDay(timings: api.data.timings, timeZone: tz)
		} catch let error as DecodingError {
			throw ServiceError.decoding(error)
		} catch let error as ServiceError {
			throw error
		} catch {
			throw ServiceError.network(error)
		}
	}
}
