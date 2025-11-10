import Foundation

/// Prayer time calculation methods supported by AlAdhan API
public enum CalculationMethod: Int, CaseIterable, Codable {
	case karachi = 1      // University of Islamic Sciences, Karachi
	case isna = 2        // Islamic Society of North America
	case mwl = 3         // Muslim World League
	case ummAlQura = 4   // Umm Al-Qura University, Makkah
	case egyptian = 5    // Egyptian General Authority of Survey
	case tehrran = 7     // Institute of Geophysics, University of Tehran
	case algeria = 12    // Algerian Ministry of Religious Affairs
	case tunisia = 13    // Tunisian Ministry of Religious Affairs
	case morocco = 14    // Moroccan Ministry of Religious Affairs
	case dubai = 15      // UAE General Authority of Islamic Affairs
	case kuwait = 16     // Kuwait Ministry of Awqaf and Islamic Affairs
	case qatar = 17      // Qatari Ministry of Awqaf and Islamic Affairs
	case singapore = 20  // Majlis Ugama Islam Singapura
	case turkey = 21     // Turkish Directorate of Religious Affairs
	
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
		case .turkey: return "Turkey"
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
		case .turkey: return "Turkey"
		}
	}
	
	public static var `default`: CalculationMethod {
		.isna
	}
}

