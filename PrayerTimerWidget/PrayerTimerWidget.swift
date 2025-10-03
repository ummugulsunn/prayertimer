import WidgetKit
import SwiftUI

struct PrayerEntry: TimelineEntry {
	let date: Date
	let prayers: [PrayerTime]
}

struct Provider: TimelineProvider {
	func placeholder(in context: Context) -> PrayerEntry {
		PrayerEntry(date: Date(), prayers: [])
	}

	func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
		let entry = PrayerEntry(date: Date(), prayers: TimingsCodec.decodeFromShared().map { TimingsCodec.buildPrayerTimes(from: $0, on: Date()) } ?? [])
		completion(entry)
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
		let now = Date()
		let prayers = TimingsCodec.decodeFromShared().map { TimingsCodec.buildPrayerTimes(from: $0, on: now) } ?? []
		let next = prayers.first(where: { $0.date > now })
		let refreshDate = next?.date.addingTimeInterval(5) ?? Calendar.current.date(byAdding: .minute, value: 30, to: now)!
		let entry = PrayerEntry(date: now, prayers: prayers)
		let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
		completion(timeline)
	}
}

struct SmallWidgetView: View {
	let prayers: [PrayerTime]
	var body: some View {
		let next = prayers.first(where: { $0.date > Date() })
		ZStack {
			// Modern gradient background
			LinearGradient(
				colors: [
					Color(red: 0.1, green: 0.2, blue: 0.4),
					Color(red: 0.15, green: 0.25, blue: 0.45)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			
			VStack(alignment: .leading, spacing: 8) {
				Text("SIRADAKİ")
					.font(.system(size: 10, weight: .bold))
					.foregroundColor(.white.opacity(0.6))
					.tracking(1)
				
				Text(next?.name ?? "-")
					.font(.system(size: 24, weight: .bold))
					.foregroundColor(.white)
				
				HStack(spacing: 4) {
					Image(systemName: "clock.fill")
						.font(.system(size: 12))
						.foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.5))
					Text(next?.timeString ?? "--:--")
						.font(.system(size: 18, weight: .semibold))
						.foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.5))
						.monospacedDigit()
				}
				
				Spacer()
			}
			.padding(16)
		}
	}
}

struct MediumWidgetView: View {
	let prayers: [PrayerTime]
	var body: some View {
		let now = Date()
		let list = prayers
		let nextIndex = list.firstIndex(where: { $0.date > now })
		let next = nextIndex.flatMap { list[$0] }
		let following = nextIndex.map { idx in Array(list.dropFirst(idx+1).prefix(2)) } ?? []
		
		ZStack {
			// Modern gradient background
			LinearGradient(
				colors: [
					Color(red: 0.1, green: 0.2, blue: 0.4),
					Color(red: 0.15, green: 0.25, blue: 0.45)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			
			VStack(alignment: .leading, spacing: 12) {
				// Sıradaki vakit - Prominent
				VStack(alignment: .leading, spacing: 4) {
					Text("SIRADAKİ VAKİT")
						.font(.system(size: 10, weight: .bold))
						.foregroundColor(.white.opacity(0.6))
						.tracking(1)
					
					HStack {
						Text(next?.name ?? "-")
							.font(.system(size: 20, weight: .bold))
							.foregroundColor(.white)
						Spacer()
						Text(next?.timeString ?? "--:--")
							.font(.system(size: 22, weight: .bold))
							.foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.5))
							.monospacedDigit()
					}
				}
				.padding(12)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(Color.white.opacity(0.1))
				)
				
				// Sonraki vakitler
				VStack(spacing: 8) {
					ForEach(following, id: \.id) { p in
						HStack {
							Circle()
								.fill(Color.white.opacity(0.3))
								.frame(width: 6, height: 6)
	Text(p.name)
								.font(.system(size: 14, weight: .medium))
								.foregroundColor(.white.opacity(0.8))
							Spacer()
							Text(p.timeString)
								.font(.system(size: 14, weight: .semibold))
								.foregroundColor(.white.opacity(0.9))
								.monospacedDigit()
						}
					}
				}
				
				Spacer()
			}
			.padding(16)
		}
	}
}

struct LargeWidgetView: View {
	let prayers: [PrayerTime]
	var body: some View {
		let now = Date()
		let nextId = prayers.first(where: { $0.date > now })?.id
		
		ZStack {
			// Modern gradient background
			LinearGradient(
				colors: [
					Color(red: 0.1, green: 0.2, blue: 0.4),
					Color(red: 0.15, green: 0.25, blue: 0.45)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			
			VStack(alignment: .leading, spacing: 12) {
				// Header
				HStack {
					VStack(alignment: .leading, spacing: 2) {
						Text("NAMAZ VAKİTLERİ")
							.font(.system(size: 11, weight: .bold))
							.foregroundColor(.white.opacity(0.6))
							.tracking(1.2)
						Text(Date(), style: .date)
							.font(.system(size: 10))
							.foregroundColor(.white.opacity(0.5))
					}
					Spacer()
					Image(systemName: "moon.stars.fill")
						.font(.system(size: 20))
						.foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.5))
				}
				.padding(.bottom, 4)
				
				// Tüm vakitler
				VStack(spacing: 10) {
					ForEach(prayers, id: \.id) { p in
						let isNext = p.id == nextId
						HStack(spacing: 12) {
							// İkon
							ZStack {
								if isNext {
									Circle()
										.fill(Color(red: 1.0, green: 0.85, blue: 0.5))
										.frame(width: 12, height: 12)
										.blur(radius: 6)
								}
								Image(systemName: isNext ? "moon.stars.fill" : "circle.fill")
									.font(.system(size: isNext ? 12 : 8))
									.foregroundColor(isNext ? Color(red: 1.0, green: 0.85, blue: 0.5) : Color.white.opacity(0.4))
							}
							.frame(width: 20)
							
							Text(p.name)
								.font(.system(size: isNext ? 16 : 14, weight: isNext ? .bold : .medium))
								.foregroundColor(isNext ? .white : .white.opacity(0.8))
							
							Spacer()
							
							Text(p.timeString)
								.font(.system(size: isNext ? 17 : 15, weight: isNext ? .bold : .semibold))
								.foregroundColor(isNext ? Color(red: 1.0, green: 0.85, blue: 0.5) : .white.opacity(0.9))
								.monospacedDigit()
						}
						.padding(.vertical, isNext ? 10 : 6)
						.padding(.horizontal, 12)
						.background(
							RoundedRectangle(cornerRadius: 10)
								.fill(isNext ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
						)
						.overlay(
							RoundedRectangle(cornerRadius: 10)
								.stroke(isNext ? Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.4) : Color.clear, lineWidth: 1.5)
						)
					}
				}
				
				Spacer()
			}
			.padding(16)
		}
	}
}

struct PrayerTimerWidget: Widget {
	let kind: String = "PrayerTimerWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			GeometryReader { geo in
				ZStack {
					switch geo.size {
					case let size where size.width <= 170: // small
						SmallWidgetView(prayers: entry.prayers)
					case let size where size.width <= 345: // medium
						MediumWidgetView(prayers: entry.prayers)
					default:
						LargeWidgetView(prayers: entry.prayers)
					}
				}
			}
		}
		.configurationDisplayName("Namaz Vakitleri")
		.description("Sıradaki vakit ve günlük vakitler")
	}
}

@main
struct PrayerTimerWidgetBundle: WidgetBundle {
	var body: some Widget {
		PrayerTimerWidget()
	}
}

