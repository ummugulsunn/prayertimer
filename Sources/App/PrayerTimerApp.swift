import SwiftUI
import AppKit

// AppDelegate - Menü çubuğu uygulaması; yanlışlıkla Cmd+Q ile çıkışı zorlaştırır, istenen çıkışa izin verir.
final class AppDelegate: NSObject, NSApplicationDelegate {
	/// `true` olduğunda `NSApplication.terminate` sonlandırmayı tamamlar (menü veya onaylı çıkış).
	static var userRequestedTermination = false
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return false
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		if Self.userRequestedTermination {
			return .terminateNow
		}
		return .terminateCancel
	}
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApp.setActivationPolicy(.accessory)
		// Ek ProcessInfo aktivitesi yok: bildirimler sistem tarafından tetiklenir; CPU/enerji maliyetini düşürür.
	}
}

// MenuBarView burada tanımlayalım
struct MenuBarContentView: View {
	@ObservedObject var viewModel: PrayerTimeViewModel
	@State private var hasStarted = false
	@State private var showSettings = false
	@State private var confirmQuit = false
	@State private var locationSearchDraft = ""
	
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
				.accessibilityLabel(showSettings ? "Ayarları kapat" : "Ayarları aç")
				Button(action: { Task { await viewModel.refreshTimings(userInitiated: true) } }) {
					Image(systemName: "arrow.clockwise")
						.font(.system(size: 12))
				}
				.buttonStyle(.borderless)
				.disabled(viewModel.isLoading)
				.accessibilityLabel("Vakitleri yenile")
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
			
			HStack(alignment: .center, spacing: 8) {
				Image(systemName: "info.circle")
					.font(.system(size: 10))
					.foregroundColor(.secondary)
				Text("Arka planda çalışır. Cmd+Q ile çıkış engellenir; aşağıdan veya ⇧⌘Q ile çıkabilirsiniz.")
					.font(.system(size: 9))
					.foregroundColor(.secondary)
					.fixedSize(horizontal: false, vertical: true)
				Spacer(minLength: 0)
				Button("Çıkış…") {
					confirmQuit = true
				}
				.font(.system(size: 9))
				.buttonStyle(.borderless)
				.foregroundColor(.secondary)
				.accessibilityLabel("Uygulamadan güvenli çıkış")
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
		}
		.frame(width: 300)
		.confirmationDialog(
			"Prayer Timer kapatılsın mı?",
			isPresented: $confirmQuit,
			titleVisibility: .visible
		) {
			Button("Kapat", role: .destructive) {
				AppDelegate.userRequestedTermination = true
				NSApplication.shared.terminate(nil)
			}
			Button("İptal", role: .cancel) { }
		} message: {
			Text("Menü çubuğundaki geri sayım ve zamanlanmış bildirimler durur.")
		}
		.onExitCommand {
			if showSettings { showSettings = false }
		}
		.onAppear {
			if !hasStarted {
				hasStarted = true
				viewModel.start()
			}
		}
		.onChange(of: showSettings) { isOpen in
			if isOpen {
				locationSearchDraft = [viewModel.manualCity, viewModel.manualCountry].filter { !$0.isEmpty }.joined(separator: ", ")
			}
		}
	}
	
	// Ayarlar Paneli
	private var settingsView: some View {
		ScrollView {
			VStack(spacing: 12) {
				// Konum Ayarları
				VStack(alignment: .leading, spacing: 8) {
					Text("Konum Ayarları")
						.font(.system(size: 12, weight: .bold))
					
					Toggle("Otomatik Konum", isOn: $viewModel.useAutoLocation)
						.font(.system(size: 11))
					
					if !viewModel.useAutoLocation {
						ManualLocationPicker(viewModel: viewModel, searchDraft: $locationSearchDraft)
					}
				}
				.padding(12)
				.background(Color.secondary.opacity(0.1))
				.cornerRadius(8)
				
				// Hesaplama Yöntemi
				VStack(alignment: .leading, spacing: 8) {
					Text("Hesaplama Yöntemi")
						.font(.system(size: 12, weight: .bold))
					
					ScrollView {
						LazyVStack(alignment: .leading, spacing: 2) {
							ForEach(CalculationMethod.allCases, id: \.self) { method in
								Button {
									viewModel.calculationMethod = method
								} label: {
									HStack {
										Text(method.shortName)
											.font(.system(size: 11))
										Spacer()
										if viewModel.calculationMethod == method {
											Image(systemName: "checkmark.circle.fill")
												.font(.system(size: 11))
												.foregroundColor(.accentColor)
										}
									}
									.padding(.vertical, 5)
									.padding(.horizontal, 8)
									.background(viewModel.calculationMethod == method ? Color.accentColor.opacity(0.12) : Color.clear)
									.cornerRadius(6)
								}
								.buttonStyle(.plain)
							}
						}
					}
					.frame(maxHeight: 140)
					
					Text(viewModel.calculationMethod.displayName)
						.font(.system(size: 9))
						.foregroundColor(.secondary)
				}
				.padding(12)
				.background(Color.secondary.opacity(0.1))
				.cornerRadius(8)
				
				// Görünüm Ayarları
				VStack(alignment: .leading, spacing: 8) {
					Text("Görünüm")
						.font(.system(size: 12, weight: .bold))
					
					Toggle("24 Saat Formatı", isOn: $viewModel.use24HourFormat)
						.font(.system(size: 11))
				}
				.padding(12)
				.background(Color.secondary.opacity(0.1))
				.cornerRadius(8)
				
				// Bildirim Ayarları
				VStack(alignment: .leading, spacing: 8) {
					Text("Bildirimler")
						.font(.system(size: 12, weight: .bold))
					
					Toggle("Bildirimleri Etkinleştir", isOn: $viewModel.notificationsEnabled)
						.font(.system(size: 11))
					
					if viewModel.notificationsEnabled {
						HStack {
							Text("Önceden hatırlat:")
								.font(.system(size: 10))
								.foregroundColor(.secondary)
							Spacer()
							Stepper(
								value: Binding(
									get: { viewModel.preAlertMinutes ?? 0 },
									set: { viewModel.preAlertMinutes = $0 == 0 ? nil : $0 }
								),
								in: 0...60,
								step: 5
							) {
								Text("\(viewModel.preAlertMinutes ?? 0) dk")
									.font(.system(size: 10))
									.frame(minWidth: 40, alignment: .trailing)
							}
						}
					}
				}
				.padding(12)
				.background(Color.secondary.opacity(0.1))
				.cornerRadius(8)
				
				// Hata mesajı göster
				if let error = viewModel.errorMessage {
					HStack {
						Image(systemName: "exclamationmark.triangle.fill")
							.foregroundColor(.orange)
						Text(error)
							.font(.system(size: 10))
							.foregroundColor(.secondary)
					}
					.padding(8)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color.orange.opacity(0.1))
					.cornerRadius(6)
				}
				
				if let success = viewModel.successMessage {
					HStack {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
						Text(success)
							.font(.system(size: 10))
							.foregroundColor(.secondary)
					}
					.padding(8)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color.green.opacity(0.12))
					.cornerRadius(6)
				}
				
				Button(action: {
					Task {
						await viewModel.refreshTimings(userInitiated: true)
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
				.disabled(viewModel.isLoading)
			}
			.padding(12)
		}
		.frame(maxHeight: 400)
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
			
			// Error message display
			if let error = viewModel.errorMessage, !viewModel.isLoading {
				HStack {
					Image(systemName: "exclamationmark.triangle.fill")
						.foregroundColor(.orange)
						.font(.system(size: 12))
					Text(error)
						.font(.system(size: 10))
						.foregroundColor(.secondary)
						.lineLimit(2)
					Spacer()
				}
				.padding(.horizontal, 12)
				.padding(.vertical, 8)
				.background(Color.orange.opacity(0.1))
			}

			if let success = viewModel.successMessage, !viewModel.isLoading {
				HStack(spacing: 6) {
					Image(systemName: "checkmark.circle.fill")
						.foregroundColor(.green)
						.font(.system(size: 12))
					Text(success)
						.font(.system(size: 10))
						.foregroundColor(.secondary)
					Spacer()
				}
				.padding(.horizontal, 12)
				.padding(.vertical, 8)
				.background(Color.green.opacity(0.12))
			}
			
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
						Task { await viewModel.refreshTimings(userInitiated: true) }
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
	
	var body: some Scene {
		MenuBarExtra {
			MenuBarContentView(viewModel: viewModel)
		} label: {
			MenuBarExtraLabel(viewModel: viewModel)
		}
		.menuBarExtraStyle(.window)
		.commands {
			CommandGroup(replacing: .appTermination) {
				Button("Prayer Timer'dan Çıkış") {
					AppDelegate.userRequestedTermination = true
					NSApplication.shared.terminate(nil)
				}
				.keyboardShortcut("q", modifiers: [.command, .shift])
			}
		}
	}
}

/// Menü çubuğu: ViewModel’den beslenir; saniyelik `TimelineView` yok (gereksiz yeniden çizim yok).
private struct MenuBarExtraLabel: View {
	@ObservedObject var viewModel: PrayerTimeViewModel

	var body: some View {
		HStack(spacing: 4) {
			Image(systemName: "moon.stars.fill")
				.font(.system(size: 13, weight: .semibold))
				.symbolRenderingMode(.monochrome)
				.foregroundStyle(.primary)
				.imageScale(.medium)
				.layoutPriority(1)
			Text(viewModel.menuBarCompactCountdown)
				.font(.system(size: 11, weight: .medium))
				.monospacedDigit()
				.foregroundStyle(viewModel.menuBarUrgentHighlight ? .orange : .primary)
		}
		.fixedSize(horizontal: true, vertical: false)
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibilitySummary)
	}

	private var accessibilitySummary: String {
		let date = Date()
		guard let next = viewModel.nextPrayer else {
			return "Namaz vakitleri, veri yok"
		}
		let remaining = max(0, Int(next.date.timeIntervalSince(date)))
		let hours = remaining / 3600
		let minutes = (remaining % 3600) / 60
		if hours > 0 {
			return "Sıradaki \(next.name), kalan süre \(hours) saat \(minutes) dakika"
		}
		return "Sıradaki \(next.name), kalan süre \(minutes) dakika"
	}
}

