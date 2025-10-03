import SwiftUI

public struct ContentView: View {
	@EnvironmentObject var viewModel: PrayerTimeViewModel
	@State private var showSettings = false
	@State private var pulseAnimation = false

	public init() {}

	public var body: some View {
		ZStack {
			// Animated gradient arka plan
			ZStack {
				LinearGradient(
					colors: [
						Color(red: 0.05, green: 0.15, blue: 0.35),
						Color(red: 0.1, green: 0.2, blue: 0.4),
						Color(red: 0.15, green: 0.25, blue: 0.45)
					],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				
				// Subtle animated circles
				Circle()
					.fill(Color.white.opacity(0.03))
					.frame(width: 400, height: 400)
					.blur(radius: 60)
					.offset(x: -100, y: -200)
				
				Circle()
					.fill(Color.blue.opacity(0.05))
					.frame(width: 300, height: 300)
					.blur(radius: 50)
					.offset(x: 150, y: 100)
					.scaleEffect(pulseAnimation ? 1.1 : 1.0)
					.animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulseAnimation)
			}
			.ignoresSafeArea()

			VStack(spacing: 0) {
				// Header
				HStack {
					VStack(alignment: .leading, spacing: 4) {
						Text("Namaz Vakitleri")
							.font(.system(size: 28, weight: .bold))
							.foregroundColor(.white)
						Text(Date(), style: .date)
							.font(.system(size: 14))
							.foregroundColor(.white.opacity(0.7))
					}
					Spacer()
					Button(action: { 
						withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
							showSettings.toggle()
						}
					}) {
						Image(systemName: "gearshape.fill")
							.font(.system(size: 20))
							.foregroundColor(.white)
							.frame(width: 44, height: 44)
							.background(
								ZStack {
									Circle()
										.fill(Color.white.opacity(0.1))
									Circle()
										.fill(
											LinearGradient(
												colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											)
										)
								}
							)
							.overlay(
								Circle()
									.stroke(Color.white.opacity(0.2), lineWidth: 1)
							)
							.shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
					}
					.buttonStyle(.plain)
					.rotationEffect(.degrees(showSettings ? 180 : 0))
					.animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSettings)
					
					Button(action: { Task { await viewModel.refreshTimings() } }) {
						Image(systemName: "arrow.clockwise")
							.font(.system(size: 20, weight: .semibold))
							.foregroundColor(.white)
							.frame(width: 44, height: 44)
							.background(
								ZStack {
									Circle()
										.fill(Color.white.opacity(0.1))
									Circle()
										.fill(
											LinearGradient(
												colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)],
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											)
										)
								}
							)
							.overlay(
								Circle()
									.stroke(Color.white.opacity(0.3), lineWidth: 1)
							)
							.shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
					}
					.buttonStyle(.plain)
					.rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
					.animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isLoading)
					.disabled(viewModel.isLoading)
					.scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
				}
				.padding(20)
				
				// Hata mesajı
				if let error = viewModel.errorMessage {
					HStack {
						Image(systemName: "exclamationmark.triangle.fill")
							.foregroundColor(.yellow)
						Text(error)
							.font(.system(size: 14))
							.foregroundColor(.white)
						Spacer()
					}
					.padding()
					.background(Color.red.opacity(0.3))
					.cornerRadius(10)
					.padding(.horizontal, 20)
					.padding(.bottom, 10)
				}

				// Loading veya boş durum
				if viewModel.isLoading {
					VStack(spacing: 16) {
						ProgressView()
							.scaleEffect(1.5)
							.tint(.white)
						Text("Namaz vakitleri yükleniyor...")
							.font(.system(size: 16))
							.foregroundColor(.white.opacity(0.8))
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 60)
				} else if viewModel.prayers.isEmpty {
					VStack(spacing: 16) {
						Image(systemName: "location.slash")
							.font(.system(size: 48))
							.foregroundColor(.white.opacity(0.5))
						Text("Namaz vakitleri yüklenemedi")
							.font(.system(size: 18, weight: .medium))
							.foregroundColor(.white)
						Text("Ayarlardan konum bilgisi girin veya\notomatik konumu açın")
							.font(.system(size: 14))
							.foregroundColor(.white.opacity(0.7))
							.multilineTextAlignment(.center)
						Button(action: { showSettings = true }) {
							Text("Ayarları Aç")
								.font(.system(size: 14, weight: .semibold))
								.foregroundColor(.white)
								.padding(.horizontal, 24)
								.padding(.vertical, 12)
								.background(Color.blue)
								.cornerRadius(20)
						}
						.buttonStyle(.plain)
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 60)
				}
				
				// Sıradaki vakit - Büyük kart (Glassmorphism)
				if let next = viewModel.nextPrayer {
					VStack(spacing: 16) {
						Text("SIRADAKİ VAKİT")
							.font(.system(size: 13, weight: .semibold))
							.foregroundColor(.white.opacity(0.7))
							.tracking(2)

						Text(next.name)
							.font(.system(size: 48, weight: .heavy))
							.foregroundColor(.white)
							.shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)

						HStack(spacing: 4) {
							Image(systemName: "clock.fill")
								.font(.system(size: 20))
								.foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.5))
							Text(next.timeString)
								.font(.system(size: 28, weight: .semibold))
								.foregroundColor(.white.opacity(0.95))
								.monospacedDigit()
						}

						// Geri sayım - Ultra prominent
						VStack(spacing: 8) {
							HStack(spacing: 12) {
								ForEach(Array(viewModel.countdownText.split(separator: ":")), id: \.self) { segment in
									Text(String(segment))
										.font(.system(size: 56, weight: .bold, design: .rounded))
										.foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.5))
										.monospacedDigit()
										.frame(minWidth: 70)
										.padding(.vertical, 12)
										.background(
											RoundedRectangle(cornerRadius: 12)
												.fill(Color.black.opacity(0.2))
										)
										.overlay(
											RoundedRectangle(cornerRadius: 12)
												.stroke(Color.white.opacity(0.1), lineWidth: 1)
										)
								}
							}
							HStack(spacing: 45) {
								Text("Saat").font(.caption).foregroundColor(.white.opacity(0.6))
								Text("Dakika").font(.caption).foregroundColor(.white.opacity(0.6))
								Text("Saniye").font(.caption).foregroundColor(.white.opacity(0.6))
							}
						}
						.padding(.top, 8)
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 36)
					.padding(.horizontal, 24)
					.background(
						ZStack {
							// Glassmorphism effect
							RoundedRectangle(cornerRadius: 24)
								.fill(Color.white.opacity(0.08))
								.background(
									RoundedRectangle(cornerRadius: 24)
										.fill(
											LinearGradient(
												colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											)
										)
								)
							RoundedRectangle(cornerRadius: 24)
								.stroke(
									LinearGradient(
										colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									),
									lineWidth: 1.5
								)
						}
					)
					.shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
					.padding(.horizontal, 20)
					.padding(.bottom, 24)
					.transition(.scale.combined(with: .opacity))
				}

				// Tüm vakitler listesi - Premium cards
				if !viewModel.prayers.isEmpty {
					VStack(alignment: .leading, spacing: 8) {
						Text("BUGÜNÜN VAKİTLERİ")
							.font(.system(size: 12, weight: .bold))
							.foregroundColor(.white.opacity(0.5))
							.tracking(1.5)
							.padding(.horizontal, 20)
							.padding(.top, 8)
						
						ScrollView(showsIndicators: false) {
							VStack(spacing: 10) {
								ForEach(Array(viewModel.prayers.enumerated()), id: \.element.id) { index, prayer in
									let isNext = viewModel.nextPrayer?.id == prayer.id
									HStack(spacing: 16) {
										// İkon with glow
										ZStack {
											if isNext {
												Circle()
													.fill(Color(red: 1.0, green: 0.85, blue: 0.5))
													.frame(width: 16, height: 16)
													.blur(radius: 8)
											}
											Image(systemName: isNext ? "moon.stars.fill" : "circle.fill")
												.font(.system(size: isNext ? 16 : 10))
												.foregroundColor(isNext ? Color(red: 1.0, green: 0.85, blue: 0.5) : Color.white.opacity(0.4))
										}
										.frame(width: 24)

										Text(prayer.name)
											.font(.system(size: isNext ? 18 : 16, weight: isNext ? .bold : .medium))
											.foregroundColor(isNext ? .white : .white.opacity(0.9))

										Spacer()

										Text(prayer.timeString)
											.font(.system(size: isNext ? 20 : 18, weight: isNext ? .bold : .semibold))
											.foregroundColor(isNext ? Color(red: 1.0, green: 0.85, blue: 0.5) : .white.opacity(0.95))
											.monospacedDigit()
									}
									.padding(.horizontal, 20)
									.padding(.vertical, isNext ? 20 : 14)
									.background(
										ZStack {
											RoundedRectangle(cornerRadius: 16)
												.fill(isNext ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
											if isNext {
												RoundedRectangle(cornerRadius: 16)
													.stroke(
														LinearGradient(
															colors: [Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.5), Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.1)],
															startPoint: .leading,
															endPoint: .trailing
														),
														lineWidth: 2
													)
											}
										}
									)
									.shadow(color: isNext ? Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.2) : Color.clear, radius: isNext ? 15 : 0, x: 0, y: isNext ? 8 : 0)
									.scaleEffect(isNext ? 1.02 : 1.0)
									.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isNext)
								}
							}
							.padding(.horizontal, 20)
							.padding(.bottom, 20)
						}
					}
				}
			}

			// Settings overlay
			if showSettings {
				Color.black.opacity(0.5)
					.ignoresSafeArea()
					.onTapGesture { showSettings = false }

				VStack(spacing: 20) {
					HStack {
						Text("Ayarlar")
							.font(.system(size: 24, weight: .bold))
							.foregroundColor(.primary)
						Spacer()
						Button(action: { showSettings = false }) {
							Image(systemName: "xmark.circle.fill")
								.font(.system(size: 24))
								.foregroundColor(.secondary)
						}
						.buttonStyle(.plain)
					}

					Toggle("Konum Otomatik", isOn: $viewModel.useAutoLocation)
						.toggleStyle(.switch)

					if !viewModel.useAutoLocation {
						VStack(alignment: .leading, spacing: 8) {
							Text("Manuel Konum").font(.caption).foregroundColor(.secondary)
							TextField("Şehir", text: $viewModel.manualCity)
								.textFieldStyle(.roundedBorder)
							TextField("Ülke", text: $viewModel.manualCountry)
								.textFieldStyle(.roundedBorder)
						}
					}

					Divider()

					Toggle("Bildirimler", isOn: $viewModel.notificationsEnabled)
						.toggleStyle(.switch)

					Stepper(value: Binding(get: { viewModel.preAlertMinutes ?? 0 }, set: { viewModel.preAlertMinutes = $0 }), in: 0...60, step: 5) {
						Text("Önceden hatırlat: \(viewModel.preAlertMinutes ?? 0) dk")
					}

					Button(action: {
						showSettings = false
						Task { await viewModel.refreshTimings() }
					}) {
						Text("Kaydet ve Güncelle")
							.font(.system(size: 16, weight: .semibold))
							.foregroundColor(.white)
							.frame(maxWidth: .infinity)
							.padding()
							.background(Color.blue)
							.cornerRadius(12)
					}
					.buttonStyle(.plain)
				}
				.padding(24)
				.frame(width: 400)
				.background(Color(NSColor.windowBackgroundColor))
				.cornerRadius(16)
				.shadow(radius: 20)
			}
		}
		.frame(minWidth: 550, minHeight: 750)
		.onAppear {
			viewModel.start()
			withAnimation(.easeInOut(duration: 3).delay(0.5)) {
				pulseAnimation = true
			}
		}
	}
}

#Preview {
	ContentView()
}

