import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

/// Zet een vrij ingevoerd adres om naar een coördinaat via Apple's geocoder.
/// Geen API-key nodig; werkt op het toestel zelf. Wordt gebruikt zodat de
/// hulpvraag op de buddy-kaart op het echte adres van de hulpvrager komt te
/// staan in plaats van op een default-punt (Amsterdam-centrum).
enum AddressGeocoder {

    /// Geocodeert een adres naar een coördinaat. Voegt automatisch ", Nederland"
    /// toe wanneer er geen land in de tekst staat, zodat losse "straat + stad"-
    /// invoer betrouwbaarder wordt gevonden. Geeft `nil` terug als het adres leeg
    /// is of niet gevonden kan worden.
    static func coordinate(for address: String) async -> CLLocationCoordinate2D? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let query = trimmed.localizedCaseInsensitiveContains("nederland")
            ? trimmed
            : "\(trimmed), Nederland"
        let placemarks = try? await CLGeocoder().geocodeAddressString(query)
        return placemarks?.first?.location?.coordinate
    }
}

// MARK: - Adres-autocomplete

/// Levert tijdens het typen exacte adres-suggesties via MapKit, regio-gebiased op
/// Nederland. Zo kiest de hulpvrager/buddy een precies adres in plaats van vrije
/// tekst die soms in de verkeerde plaats geocodeert (bijv. "Prof. Lorentzlaan 56"
/// dat anders in Amstelveen i.p.v. de juiste stad belandt). Het gekozen adres
/// levert direct de exacte coördinaat van MapKit op.
final class AddressSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        // Bias op Nederland zodat suggesties lokaal en exact zijn.
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.1326, longitude: 5.2913),
            span: MKCoordinateSpan(latitudeDelta: 3.2, longitudeDelta: 3.6)
        )
    }

    /// Update de zoekterm. Onder de 3 tekens tonen we niets (te ruis-gevoelig).
    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            suggestions = []
            completer.queryFragment = ""
            return
        }
        completer.queryFragment = trimmed
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }

    /// Zet een gekozen suggestie om naar een exacte coördinaat + nette adrestekst.
    func resolve(_ completion: MKLocalSearchCompletion) async -> (CLLocationCoordinate2D, String)? {
        let request = MKLocalSearch.Request(completion: completion)
        guard let response = try? await MKLocalSearch(request: request).start(),
              let item = response.mapItems.first else { return nil }
        let coord = item.placemark.coordinate
        return (coord, Self.formatted(from: item.placemark, fallback: completion))
    }

    static func formatted(from placemark: MKPlacemark, fallback: MKLocalSearchCompletion) -> String {
        var parts: [String] = []
        let street = [placemark.thoroughfare, placemark.subThoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        if !street.isEmpty { parts.append(street) }
        if let city = placemark.locality { parts.append(city) }
        if parts.isEmpty {
            let combined = [fallback.title, fallback.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
            return combined.isEmpty ? fallback.title : combined
        }
        return parts.joined(separator: ", ")
    }

    // MARK: MKLocalSearchCompleterDelegate (callbacks komen op de main-thread)
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

/// Adresveld met live suggesties. Bind de tekst aan je adres-state; `onSelect`
/// geeft de exacte coördinaat + nette adrestekst zodra een suggestie wordt
/// gekozen. `onManualEdit` vuurt bij handmatig typen (zodat de aanroeper een
/// eerder gekozen coördinaat kan vergeten).
struct AddressAutocompleteField: View {
    let placeholder: String
    @Binding var text: String
    var font: Font = BCTypography.body
    var onManualEdit: (() -> Void)? = nil
    var onSelect: (CLLocationCoordinate2D, String) -> Void

    @StateObject private var search = AddressSearchService()
    @FocusState private var focused: Bool
    @State private var suppressNextChange = false

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BCColors.textTertiary)
                TextField(placeholder, text: $text)
                    .font(font)
                    .textContentType(.fullStreetAddress)
                    .autocorrectionDisabled()
                    .focused($focused)
                if !text.isEmpty {
                    Button {
                        text = ""
                        search.clear()
                        onManualEdit?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(BCSpacing.md)
            .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).fill(BCColors.surface))
            .overlay(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).stroke(BCColors.border, lineWidth: 1))

            if focused && !search.suggestions.isEmpty {
                let items = Array(search.suggestions.prefix(5))
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, suggestion in
                        Button { choose(suggestion) } label: {
                            HStack(spacing: BCSpacing.sm) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(BCColors.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(BCTypography.caption)
                                            .foregroundStyle(BCColors.textSecondary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, BCSpacing.sm)
                            .padding(.horizontal, BCSpacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if idx < items.count - 1 {
                            Divider().padding(.leading, BCSpacing.xl)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).fill(BCColors.surface))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).stroke(BCColors.border, lineWidth: 1))
                .bcSoftShadow(.raised)
            }
        }
        .onChange(of: text) { _, newValue in
            if suppressNextChange { suppressNextChange = false; return }
            search.update(query: newValue)
            onManualEdit?()
        }
    }

    private func choose(_ completion: MKLocalSearchCompletion) {
        focused = false
        search.clear()
        suppressNextChange = true
        text = completion.subtitle.isEmpty ? completion.title : "\(completion.title), \(completion.subtitle)"
        Task {
            guard let (coord, formatted) = await search.resolve(completion) else { return }
            await MainActor.run {
                suppressNextChange = true
                text = formatted
                onSelect(coord, formatted)
            }
        }
    }
}
