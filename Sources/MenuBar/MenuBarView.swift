import SwiftUI

public struct MenuBarView: View {
	@ObservedObject var viewModel: PrayerTimeViewModel
	
	public init(viewModel: PrayerTimeViewModel) {
		self.viewModel = viewModel
	}
	
	public var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				VStack(alignment: .leading, spacing: 2) {
					Text("Namaz Vakitleri")
						.font(.system(size: 13, weight: .bold))
						.foregroundColor(.primary)
					Text(Date(), style: .date)
						.font(.system(size: 10))
						.foregroundColor(.secondary)
				}
				Spacer()
				Button(action: { Task { await viewModel.refreshTimings() } }) {
					Image(systemName: "arrow.clockwise")
						.font(.system(size: 12))
				}
				.buttonStyle(.borderless)
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(Color(NSColor.controlBackgroundColor))
			
			Divider()
			
			// Sıradaki vakit - Compact
			if let next = viewModel.nextPrayer {
				VStack(spacing: 8) {
					HStack {
						Image(systemName: "moon.stars.fill")
							.font(.system(size: 14))
							.foregroundColor(.orange)
						Text(next.name)
							.font(.system(size: 14, weight: .semibold))
						Spacer()
						Text(next.timeString)
							.font(.system(size: 14, weight: .bold))
							.foregroundColor(.orange)
							.monospacedDigit()
					}
					
					// Countdown
					Text(viewModel.countdownText)
						.font(.system(size: 20, weight: .bold, design: .rounded))
						.foregroundColor(.orange)
						.monospacedDigit()
				}
				.padding(12)
				.background(Color.orange.opacity(0.1))
			}
			
			Divider()
			
			// Tüm vakitler - Kompakt liste
			ScrollView {
				VStack(spacing: 6) {
					ForEach(viewModel.prayers) { prayer in
						let isNext = viewModel.nextPrayer?.id == prayer.id
						HStack {
							Circle()
								.fill(isNext ? Color.orange : Color.secondary.opacity(0.3))
								.frame(width: 6, height: 6)
							Text(prayer.name)
								.font(.system(size: 12, weight: isNext ? .semibold : .regular))
								.foregroundColor(isNext ? .primary : .secondary)
							Spacer()
							Text(prayer.timeString)
								.font(.system(size: 12, weight: isNext ? .bold : .medium))
								.foregroundColor(isNext ? .orange : .primary)
								.monospacedDigit()
						}
						.padding(.horizontal, 12)
						.padding(.vertical, 4)
					}
				}
			}
			.frame(maxHeight: 200)
		}
		.frame(width: 250)
	}
}

