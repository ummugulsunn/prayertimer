import SwiftUI

/// Manuel konum: arama + kaydırılabilir sonuç listesi; satır seçilince şehir/ülke doldurulur.
public struct ManualLocationPicker: View {
	@ObservedObject var viewModel: PrayerTimeViewModel
	@Binding var searchDraft: String
	@FocusState private var searchFocused: Bool

	public init(viewModel: PrayerTimeViewModel, searchDraft: Binding<String>) {
		self.viewModel = viewModel
		self._searchDraft = searchDraft
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Konum ara")
				.font(.system(size: 10))
				.foregroundColor(.secondary)
			TextField("Şehir veya adres yazın", text: $searchDraft)
				.textFieldStyle(.roundedBorder)
				.font(.system(size: 11))
				.focused($searchFocused)
				.onChange(of: searchDraft) { newValue in
					viewModel.scheduleDebouncedLocationSearch(query: newValue)
				}
				.onSubmit {
					searchFocused = false
				}

			if !viewModel.mapLocationSearchResults.isEmpty {
				Text("Sonuçlar — birini seçin")
					.font(.system(size: 9))
					.foregroundColor(.secondary)
					.padding(.top, 2)

				ScrollView {
					LazyVStack(alignment: .leading, spacing: 0) {
						ForEach(viewModel.mapLocationSearchResults) { row in
							Button {
								viewModel.applyMapLocationSearchResult(row)
								searchDraft = [row.city, row.country].filter { !$0.isEmpty }.joined(separator: ", ")
								searchFocused = false
							} label: {
								VStack(alignment: .leading, spacing: 2) {
									Text(row.title)
										.font(.system(size: 11, weight: .medium))
										.foregroundColor(.primary)
									if !row.subtitle.isEmpty {
										Text(row.subtitle)
											.font(.system(size: 9))
											.foregroundColor(.secondary)
									}
								}
								.frame(maxWidth: .infinity, alignment: .leading)
								.padding(.vertical, 6)
								.padding(.horizontal, 8)
							}
							.buttonStyle(.plain)
							Divider()
						}
					}
				}
				.frame(maxHeight: 160)
				.background(Color.secondary.opacity(0.06))
				.cornerRadius(6)
			}

			VStack(alignment: .leading, spacing: 4) {
				Text("Seçilen")
					.font(.system(size: 9))
					.foregroundColor(.secondary)
				HStack(spacing: 6) {
					Text(viewModel.manualCity)
						.font(.system(size: 10))
						.lineLimit(1)
					Text("·")
						.foregroundColor(.secondary)
					Text(viewModel.manualCountry)
						.font(.system(size: 10))
						.lineLimit(1)
				}
			}
			.padding(.top, 4)
		}
		.onDisappear {
			viewModel.clearMapLocationSearchResults()
		}
	}
}
