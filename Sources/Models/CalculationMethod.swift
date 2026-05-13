import Foundation

/// Prayer time calculation methods supported by AlAdhan API
/// Ham değerler https://api.aladhan.com/v1/methods ile bire bir eşleşmeli.
public enum CalculationMethod: Int, CaseIterable, Codable {
	case karachi = 1      // University of Islamic Sciences, Karachi
	case isna = 2         // Islamic Society of North America
	case mwl = 3          // Muslim World League
	case ummAlQura = 4    // Umm Al-Qura University, Makkah
	case egyptian = 5     // Egyptian General Authority of Survey
	case tehrran = 7      // Institute of Geophysics, University of Tehran
	case kuwait = 9       // Kuwait
	case qatar = 10       // Qatar
	case singapore = 11   // Majlis Ugama Islam Singapura
	case turkey = 13      // Diyanet İşleri Başkanlığı, Turkey
	case dubai = 16       // Dubai (experimental)
	case tunisia = 18     // Tunisia
	case algeria = 19     // Algeria
	case morocco = 21     // Morocco
	
	public var displayName: String {
		switch self {
		case .karachi: return "Karachi (University of Islamic Sciences)"
		case .isna: return "ISNA (Islamic Society of North America)"
		case .mwl: return "MWL (Muslim World League)"
		case .ummAlQura: return "Umm Al-Qura (Makkah)"
		case .egyptian: return "Egyptian General Authority"
		case .tehrran: return "Tehran (Institute of Geophysics)"
		case .algeria: return "Algeria"
		case .tunisia: return "Tunisia"
		case .morocco: return "Morocco"
		case .dubai: return "Dubai (UAE)"
		case .kuwait: return "Kuwait"
		case .qatar: return "Qatar"
		case .singapore: return "Singapore"
		case .turkey: return "Türkiye Diyanet İşleri Başkanlığı"
		}
	}
	
	public var shortName: String {
		switch self {
		case .karachi: return "Karachi"
		case .isna: return "ISNA"
		case .mwl: return "MWL"
		case .ummAlQura: return "Umm Al-Qura"
		case .egyptian: return "Egyptian"
		case .tehrran: return "Tehran"
		case .algeria: return "Algeria"
		case .tunisia: return "Tunisia"
		case .morocco: return "Morocco"
		case .dubai: return "Dubai"
		case .kuwait: return "Kuwait"
		case .qatar: return "Qatar"
		case .singapore: return "Singapore"
		case .turkey: return "Türkiye Diyanet İşleri Başkanlığı"
		}
	}
	
	public static var `default`: CalculationMethod {
		.turkey // Türkiye için varsayılan olarak Diyanet yöntemi
	}
}

