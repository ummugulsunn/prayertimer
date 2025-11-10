import Foundation
import CoreLocation

public final class LocationManager: NSObject, CLLocationManagerDelegate {
	private let manager = CLLocationManager()
	private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
	private var authorizationContinuation: CheckedContinuation<Void, Error>?

	public override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyKilometer // Daha hızlı sonuç için
	}

	public enum LocationError: Error {
		case denied
		case restricted
		case unableToFindLocation
	}

	public func requestOneShotLocation() async throws -> CLLocationCoordinate2D {
		// Önce izin durumunu kontrol et ve gerekirse izin iste
		let status = await MainActor.run { manager.authorizationStatus }
		
		if status == .notDetermined {
			// İzin iste ve sonucu bekle
			await MainActor.run {
				manager.requestWhenInUseAuthorization()
			}
			
			// İzin durumu değişikliğini bekle (maksimum 10 saniye)
			try await withThrowingTaskGroup(of: Void.self) { group in
				// İzin durumu değişikliğini bekle
				group.addTask {
					return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
						Task { @MainActor in
							self.authorizationContinuation = continuation
						}
					}
				}
				
				// Timeout (10 saniye)
				group.addTask {
					try await Task.sleep(nanoseconds: 10_000_000_000)
					throw LocationError.denied
				}
				
				// İlk tamamlanan task'ı bekle
				try await group.next()!
				group.cancelAll()
			}
		}
		
		// İzin durumunu tekrar kontrol et
		let finalStatus = await MainActor.run { manager.authorizationStatus }
		switch finalStatus {
		case .denied:
			throw LocationError.denied
		case .restricted:
			throw LocationError.restricted
		case .authorizedAlways:
			break
		case .notDetermined:
			throw LocationError.denied
		@unknown default:
			throw LocationError.unableToFindLocation
		}

		// Konum servislerinin aktif olduğundan emin ol
		let locationServicesEnabled = await MainActor.run {
			CLLocationManager.locationServicesEnabled()
		}
		guard locationServicesEnabled else {
			throw LocationError.restricted
		}
		
		// Konum iste (timeout ile)
		return try await withThrowingTaskGroup(of: CLLocationCoordinate2D.self) { group in
			// Konum isteği
			group.addTask {
				return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocationCoordinate2D, Error>) in
					Task { @MainActor in
						self.continuation = continuation
						self.manager.requestLocation()
					}
				}
			}
			
			// Timeout (15 saniye)
			group.addTask {
				try await Task.sleep(nanoseconds: 15_000_000_000)
				throw LocationError.unableToFindLocation
			}
			
			// İlk tamamlanan task'ı al
			let result = try await group.next()!
			group.cancelAll()
			return result
		}
	}
	
	public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		let status = manager.authorizationStatus
		if status != .notDetermined {
			// İzin durumu belirlendi, continuation'ı resume et
			if let authContinuation = authorizationContinuation {
				if status == .authorizedAlways {
					authContinuation.resume()
				} else {
					authContinuation.resume(throwing: LocationError.denied)
				}
				authorizationContinuation = nil
			}
		}
	}

	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let coordinate = locations.first?.coordinate else {
			continuation?.resume(throwing: LocationError.unableToFindLocation)
			continuation = nil
			return
		}
		continuation?.resume(returning: coordinate)
		continuation = nil
	}

	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		continuation?.resume(throwing: error)
		continuation = nil
	}
}

