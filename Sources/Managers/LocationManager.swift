import Foundation
import CoreLocation

public final class LocationManager: NSObject, CLLocationManagerDelegate {
	private let manager = CLLocationManager()
	private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

	public override init() {
		super.init()
		manager.delegate = self
	}

	public enum LocationError: Error {
		case denied
		case restricted
		case unableToFindLocation
	}

	public func requestOneShotLocation() async throws -> CLLocationCoordinate2D {
		switch manager.authorizationStatus {
		case .notDetermined:
			manager.requestWhenInUseAuthorization()
		case .denied:
			throw LocationError.denied
		case .restricted:
			throw LocationError.restricted
		case .authorizedAlways, .authorizedWhenInUse:
			break
		@unknown default:
			break
		}

		return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocationCoordinate2D, Error>) in
			self.continuation = continuation
			self.manager.requestLocation()
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

