import SwiftUI
import AppKit

// AppDelegate - Uygulamanın sürekli çalışmasını sağlar
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		// Ana pencere kapansa bile uygulama kapanmasın
		return false
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		// CMD+Q ile kapatmayı engelle - uygulama sürekli çalışsın
		// Sadece Activity Monitor'dan kapatılabilir
		return .terminateCancel
	}
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		// Ana pencereyi gizle (sadece menu bar app olarak çalışsın)
		NSApp.setActivationPolicy(.accessory)
	}
}

// MenuBarView burada tanımlayalım
struct MenuBarContentView: View {
	@ObservedObject var viewModel: PrayerTimeViewModel
	@State private var hasStarted = false
	@State private var showSettings = false
	
	var body: some View {
		VStack(spacing: 0) {
			// Header - Kalan Süre ile
			HStack {
				VStack(alignment: .leading, spacing: 2) {
					Text("Namaz Vakitleri")
						.font(.system(size: 13, weight: .bold))
					if let next = viewModel.nextPrayer {
						HStack(spacing: 4) {
							Image(systemName: "clock.fill")
								.font(.system(size: 9))
								.foregroundColor(.orange)
							Text(viewModel.countdownText)
								.font(.system(size: 11, weight: .semibold, design: .rounded))
								.foregroundColor(.orange)
								.monospacedDigit()
							Text("- \(next.name)")
								.font(.system(size: 10))
								.foregroundColor(.secondary)
						}
					} else {
						Text(Date(), style: .date)
							.font(.system(size: 10))
							.foregroundColor(.secondary)
					}
				}
				Spacer()
				Button(action: { showSettings.toggle() }) {
					Image(systemName: "gear")
						.font(.system(size: 12))
				}
				.buttonStyle(.borderless)
				Button(action: { Task { await viewModel.refreshTimings() } }) {
					Image(systemName: "arrow.clockwise")
						.font(.system(size: 12))
				}
				.buttonStyle(.borderless)
			}
			.padding(12)
			
			Divider()
			
			// Ayarlar veya Ana İçerik
			if showSettings {
				settingsView
			} else {
				mainContentView
			}
			
			Divider()
			
			// Bilgi metni
			HStack {
				Image(systemName: "info.circle")
					.font(.system(size: 10))
					.foregroundColor(.secondary)
				Text("Uygulama sürekli çalışır. Kapatmak için Activity Monitor kullanın.")
					.font(.system(size: 9))
					.foregroundColor(.secondary)
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
		}
		.frame(width: 280)
		.onAppear {
			// Sadece bir kere başlat
			if !hasStarted {
				hasStarted = true
				viewModel.start()
			}
		}
	}
	
	// Ayarlar Paneli
	private var settingsView: some View {
		VStack(spacing: 12) {
			VStack(alignment: .leading, spacing: 8) {
				Text("Konum Ayarları")
					.font(.system(size: 12, weight: .bold))
				
				Toggle("Otomatik Konum", isOn: $viewModel.useAutoLocation)
					.font(.system(size: 11))
				
				if !viewModel.useAutoLocation {
					VStack(alignment: .leading, spacing: 6) {
						Text("Şehir")
							.font(.system(size: 10))
							.foregroundColor(.secondary)
						TextField("İstanbul", text: $viewModel.manualCity)
							.textFieldStyle(.roundedBorder)
							.font(.system(size: 11))
						
						Text("Ülke")
							.font(.system(size: 10))
							.foregroundColor(.secondary)
						TextField("Turkey", text: $viewModel.manualCountry)
							.textFieldStyle(.roundedBorder)
							.font(.system(size: 11))
					}
				}
			}
			.padding(12)
			.background(Color.secondary.opacity(0.1))
			.cornerRadius(8)
			
			Button(action: {
				Task {
					await viewModel.refreshTimings()
					showSettings = false
				}
			}) {
				HStack {
					Image(systemName: "checkmark.circle.fill")
					Text("Kaydet ve Güncelle")
				}
				.frame(maxWidth: .infinity)
			}
			.buttonStyle(.borderedProminent)
			.controlSize(.small)
		}
		.padding(12)
	}
	
	// Ana İçerik
	private var mainContentView: some View {
		VStack(spacing: 0) {
			// Sıradaki vakit
			if let next = viewModel.nextPrayer {
				VStack(spacing: 8) {
					HStack {
						Image(systemName: "moon.stars.fill")
							.foregroundColor(.orange)
						Text(next.name)
							.font(.system(size: 14, weight: .semibold))
						Spacer()
						Text(next.timeString)
							.font(.system(size: 14, weight: .bold))
							.foregroundColor(.orange)
							.monospacedDigit()
					}
					Text(viewModel.countdownText)
						.font(.system(size: 20, weight: .bold, design: .rounded))
						.foregroundColor(.orange)
						.monospacedDigit()
				}
				.padding(12)
				.background(Color.orange.opacity(0.1))
			}
			
			Divider()
			
			// Vakitler listesi veya loading
			if viewModel.isLoading {
				VStack(spacing: 8) {
					ProgressView()
					Text("Yükleniyor...")
						.font(.caption)
						.foregroundColor(.secondary)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 20)
			} else if viewModel.prayers.isEmpty {
				VStack(spacing: 12) {
					Image(systemName: "location.slash")
						.font(.system(size: 32))
						.foregroundColor(.secondary.opacity(0.5))
					Text("Namaz vakitleri henüz yüklenmedi")
						.font(.caption)
						.foregroundColor(.secondary)
						.multilineTextAlignment(.center)
					Button("Yenile") {
						Task { await viewModel.refreshTimings() }
					}
					.buttonStyle(.borderedProminent)
					.controlSize(.small)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 20)
			} else {
				ScrollView {
					VStack(spacing: 4) {
						ForEach(viewModel.prayers) { prayer in
							let isNext = viewModel.nextPrayer?.id == prayer.id
							HStack {
								Circle()
									.fill(isNext ? Color.orange : Color.secondary.opacity(0.3))
									.frame(width: 6, height: 6)
								Text(prayer.name)
									.font(.system(size: 12, weight: isNext ? .semibold : .regular))
								Spacer()
								Text(prayer.timeString)
									.font(.system(size: 12, weight: isNext ? .bold : .medium))
									.foregroundColor(isNext ? .orange : .primary)
									.monospacedDigit()
							}
							.padding(.horizontal, 12)
							.padding(.vertical, 6)
						}
					}
				}
				.frame(maxHeight: 220)
			}
		}
	}
}

@main
struct PrayerTimerApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@StateObject private var viewModel = PrayerTimeViewModel()
	
	init() {
		// Uygulama başladığında menu bar'ı göster
		// Ana pencere hiç açılmasın
		
		// CMD+Q kısayolunu tamamen devre dışı bırak
		DispatchQueue.main.async {
			NSApp.mainMenu?.items.forEach { menuItem in
				if menuItem.title == "Prayer Timer" || menuItem.title == "PrayerTimer" {
					menuItem.submenu?.items.removeAll(where: { $0.action == #selector(NSApplication.terminate(_:)) })
				}
			}
		}
	}
	
	var body: some Scene {
		// MenuBar - Sürekli üstte
		MenuBarExtra {
			MenuBarContentView(viewModel: viewModel)
		} label: {
			HStack(spacing: 3) {
				Image(systemName: "moon.stars.fill")
					.font(.system(size: 12))
				if let next = viewModel.nextPrayer {
					// Kalan süreyi göster
					let remaining = max(0, Int(next.date.timeIntervalSinceNow))
					let hours = remaining / 3600
					let minutes = (remaining % 3600) / 60
					
					if hours > 0 {
						Text("\(hours)s \(minutes)dk")
							.font(.system(size: 11, weight: .medium))
					} else {
						Text("\(minutes)dk")
							.font(.system(size: 11, weight: .medium))
							.foregroundColor(minutes < 15 ? .orange : .primary)
					}
				} else {
					Text("--")
						.font(.system(size: 11))
				}
			}
		}
		.menuBarExtraStyle(.window)
		.commands {
			// Quit komutunu kaldır
			CommandGroup(replacing: .appTermination) { }
		}
	}
}

