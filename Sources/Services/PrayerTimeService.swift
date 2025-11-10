import Foundation

public final class PrayerTimeService {
	public enum ServiceError: Error {
		case invalidURL
		case network(Error)
		case decoding(Error)
		case invalidResponse
	}

	public init() {}

	public struct FetchParams {
		public let date: Date
		public let latitude: Double
		public let longitude: Double
		public let method: Int?
		public init(date: Date = Date(), latitude: Double, longitude: Double, method: Int? = nil) {
			self.date = date
			self.latitude = latitude
			self.longitude = longitude
			self.method = method
		}
	}

	public func fetchTimings(params: FetchParams) async throws -> Timings {
		var components = URLComponents(string: "https://api.aladhan.com/v1/timings")
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd-MM-yyyy"
		let dateString = dateFormatter.string(from: params.date)
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
			let (data, response) = try await URLSession.shared.data(for: request)
			guard let http = response as? HTTPURLResponse else {
				throw ServiceError.invalidResponse
			}
			
			guard (200..<300).contains(http.statusCode) else {
				// Provide more context for HTTP errors
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
			return api.data.timings
		} catch let error as DecodingError {
			throw ServiceError.decoding(error)
		} catch let error as ServiceError {
			// Re-throw service errors as-is
			throw error
		} catch {
			throw ServiceError.network(error)
		}
	}
}


