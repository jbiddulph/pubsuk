import Foundation
import MapKit
import Supabase

struct VenueAnnotation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    let title: String
}

class VenueMapViewModel: NSObject, ObservableObject {
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    @Published var venueAnnotations: [VenueAnnotation] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedVenue: Venue? = nil
    @Published var allVenues: [Venue] = []
    @Published var tooManyMarkers: Bool = false
    let markerLimit = 1000
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )

    override init() {
        super.init()
        Task { await fetchAllVenues() }
    }

    func fetchAllVenues() async {
        isLoading = true
        error = nil
        var allVenues: [Venue] = []
        let pageSize = 1000
        var page = 0
        let maxPages = 100
        do {
            while page < maxPages {
                let from = page * pageSize
                let to = from + pageSize - 1
                let response = try await client
                    .from("Venue")
                    .select()
                    .range(from: from, to: to)
                    .execute()
                let venues = try JSONDecoder().decode([Venue].self, from: response.data)
                allVenues.append(contentsOf: venues)
                if venues.count < pageSize { break }
                page += 1
            }
            DispatchQueue.main.async {
                self.allVenues = allVenues
                self.updateVisibleMarkers()
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func updateVisibleMarkers() {
        let region = self.region
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        let visibleVenues = allVenues.filter { venue in
            if let latStr = venue.latitude, let lonStr = venue.longitude,
               let lat = Double(latStr), let lon = Double(lonStr) {
                return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
            }
            return false
        }
        if visibleVenues.count > markerLimit {
            self.tooManyMarkers = true
        } else {
            self.tooManyMarkers = false
        }
        let limitedVenues = visibleVenues.prefix(markerLimit)
        let annotations = limitedVenues.compactMap { venue -> VenueAnnotation? in
            if let latStr = venue.latitude, let lonStr = venue.longitude,
               let lat = Double(latStr), let lon = Double(lonStr) {
                return VenueAnnotation(id: venue.id, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), title: venue.venuename)
            }
            return nil
        }
        self.venueAnnotations = Array(annotations)
    }

    func regionDidChange(_ region: MKCoordinateRegion) {
        DispatchQueue.main.async {
            self.region = region
            self.updateVisibleMarkers()
        }
    }
} 