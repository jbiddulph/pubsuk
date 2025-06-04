//
//  ContentView.swift
//  PUBSUKx
//
//  Created by John Biddulph on 02/06/2025.
//

import SwiftUI
import Supabase
import MapKit
import PhotosUI

struct Venue: Identifiable, Decodable {
    let id: Int
    let fsa_id: Int?
    let venuename: String
    let slug: String?
    let venuetype: String?
    let address: String
    let address2: String?
    let town: String
    let county: String
    let postcode: String
    let postalsearch: String?
    let telephone: String?
    let easting: String?
    let northing: String?
    let latitude: String?
    let longitude: String?
    let local_authority: String?
    let website: String?
    let photo: String?
    let is_live: String?
    let created_at: String?
    let updated_at: String?
}

// Add City and Category model structs
struct City: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
}

struct Category: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
}

struct Event: Identifiable, Decodable {
    let id: Int
    let event_title: String
    let event_start: String?
    let description: String?
    let listingId: Int?
    let cost: String?
    let duration: String?
    let website: String?
    let photo: String?
}

// Update Event struct to include venue info
struct EventWithVenue: Identifiable, Decodable {
    let id: Int
    let event_title: String
    let event_start: String?
    let description: String?
    let listingId: Int?
    let cost: String?
    let duration: String?
    let website: String?
    let photo: String?
    let venue: VenueSummary?
}

struct VenueSummary: Decodable {
    let id: Int
    let venuename: String
}

// MARK: - Color Extension
extension Color {
    static let secondaryBlue = Color(hex: "#1E2937")
    static let darkBlue = Color(hex: "#111827")
    static let primaryOrange = Color(hex: "#F59E0B")
    static let appWhite = Color(hex: "#FFFFFF")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var selectedVenueFromEvent: Venue? = nil
    @State private var isDashboardPresented = false
    @State private var userRole: String? = nil
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                VenuesListView()
                    .navigationTitle("Venues")
                    .background(Color.darkBlue)
            }
            .tabItem {
                Label {
                    Text("List").font(.custom("Kanit-SemiBold", size: 16))
                        .foregroundColor(selectedTab == 0 ? .primaryOrange : .appWhite)
                } icon: {
                    Image(systemName: "list.bullet")
                        .foregroundColor(selectedTab == 0 ? .primaryOrange : .appWhite)
                }
            }
            .tag(0)
            NavigationView {
                VenueMapView(selectedTab: $selectedTab)
                    .navigationTitle("Map")
                    .background(Color.darkBlue)
            }
            .tabItem {
                Label {
                    Text("Map").font(.custom("Kanit-SemiBold", size: 16))
                        .foregroundColor(selectedTab == 1 ? .primaryOrange : .appWhite)
                } icon: {
                    Image(systemName: "map")
                        .foregroundColor(selectedTab == 1 ? .primaryOrange : .appWhite)
                }
            }
            .tag(1)
            NavigationView {
                EventsListView(selectedVenueFromEvent: $selectedVenueFromEvent)
                    .background(Color.darkBlue)
            }
            .tabItem {
                Label {
                    Text("Events").font(.custom("Kanit-SemiBold", size: 16))
                        .foregroundColor(selectedTab == 2 ? .primaryOrange : .appWhite)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(selectedTab == 2 ? .primaryOrange : .appWhite)
                }
            }
            .tag(2)
            NavigationView {
                DashboardView(userRole: $userRole)
                    .navigationTitle("Dashboard")
                    .background(Color.darkBlue)
            }
            .tabItem {
                Label {
                    Text("Dashboard").font(.custom("Kanit-SemiBold", size: 16))
                        .foregroundColor(selectedTab == 3 ? .primaryOrange : .appWhite)
                } icon: {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(selectedTab == 3 ? .primaryOrange : .appWhite)
                }
            }
            .tag(3)
        }
        .accentColor(.primaryOrange)
        .background(Color.secondaryBlue)
        .font(.custom("Kanit-Regular", size: 20))
        .sheet(item: $selectedVenueFromEvent) { venue in
            VenueDetailView(venue: venue, onClose: { selectedVenueFromEvent = nil })
        }
    }
}

// Move the existing list logic into VenuesListView
struct VenuesListView: View {
    @State private var venues: [Venue] = []
    @State private var page: Int = 0
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var selectedVenue: Venue? = nil
    let pageSize = 500
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(venues) { venue in
                        VStack(spacing: 0) {
                            Button(action: { selectedVenue = venue }) {
                                VStack(alignment: .leading) {
                                    Text(venue.venuename)
                                        .font(.custom("Kanit-SemiBold", size: 24))
                                        .foregroundColor(.primaryOrange)
                                    Text(venue.address)
                                        .foregroundColor(.appWhite)
                                    Text("\(venue.town), \(venue.county), \(venue.postcode)")
                                        .foregroundColor(.appWhite)
                                    if let website = venue.website, !website.isEmpty, website != "NULL" {
                                        Text(website).foregroundColor(.primaryOrange)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondaryBlue)
                            }
                            Divider()
                                .background(Color.primaryOrange)
                        }
                        .listRowInsets(EdgeInsets())
                        .background(Color.secondaryBlue)
                    }
                }
                .font(.custom("Kanit-Regular", size: 20))
                .background(Color.secondaryBlue)
                .listStyle(PlainListStyle())
            }
            HStack {
                Button("Previous") {
                    if page > 0 {
                        page -= 1
                        fetchVenues()
                    }
                }
                .disabled(page == 0 || isLoading)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.primaryOrange)
                .foregroundColor(.appWhite)
                .cornerRadius(8)
                .font(.custom("Kanit-SemiBold", size: 14))
                Spacer()
                // Page number in appWhite
                Text("Page \(page + 1)")
                    .foregroundColor(.appWhite)
                    .font(.custom("Kanit-SemiBold", size: 14))
                Spacer()
                Button("Next") {
                    if hasMore {
                        page += 1
                        fetchVenues()
                    }
                }
                .disabled(!hasMore || isLoading)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.primaryOrange)
                .foregroundColor(.appWhite)
                .cornerRadius(8)
                .font(.custom("Kanit-SemiBold", size: 14))
            }
            .padding()
            .background(Color.darkBlue)
        }
        .onAppear(perform: fetchVenues)
        .sheet(item: $selectedVenue) { venue in
            VenueDetailView(venue: venue, onClose: { selectedVenue = nil })
        }
        .font(.custom("Kanit-Regular", size: 20))
        .background(Color.secondaryBlue)
    }
    func fetchVenues() {
        isLoading = true
        hasMore = true
        venues = []
        Task {
            do {
                let from = page * pageSize
                let to = from + pageSize - 1
                let response = try await client
                    .from("Venue")
                    .select()
                    .order("id", ascending: true)
                    .range(from: from, to: to)
                    .execute()
                let decoded = try JSONDecoder().decode([Venue].self, from: response.data)
                DispatchQueue.main.async {
                    venues = decoded
                    hasMore = decoded.count == pageSize
                    isLoading = false
                    print("[DEBUG] Venues loaded: \(venues.count)")
                    print("[DEBUG] Venue IDs: \(venues.map { $0.id })")
                }
            } catch {
                DispatchQueue.main.async {
                    venues = []
                    hasMore = false
                    isLoading = false
                    print("[DEBUG] Failed to load venues: \(error)")
                }
            }
        }
    }
}

// Placeholder for the new map view
struct VenueMapView: View {
    @StateObject private var viewModel = VenueMapViewModel()
    @State private var showMenu = false
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        ZStack {
            Color.darkBlue.ignoresSafeArea()
            ClusteredVenueMapView(viewModel: viewModel)
            VStack {
                HStack {
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title)
                            .padding(12)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding([.top, .leading], 16)
                    Spacer()
                }
                Spacer()
            }
            if let error = viewModel.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
            if viewModel.tooManyMarkers {
                VStack {
                    Spacer()
                    Text("Too many venues to display, zoom in to see markers.")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .padding()
                }
            }
            if let venue = viewModel.selectedVenue {
                VenueDetailView(venue: venue, onClose: { viewModel.selectedVenue = nil })
                    .background(Color(.systemBackground).opacity(0.95))
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .padding()
                    .onTapGesture { viewModel.selectedVenue = nil }
            }
            // Slide-out menu
            if showMenu {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { showMenu = false }
                    .zIndex(1)
                HStack {
                    VStack(alignment: .leading, spacing: 32) {
                        Button(action: {
                            selectedTab = 1
                            showMenu = false
                        }) {
                            Label("Map", systemImage: "map")
                                .font(.title2)
                        }
                        Button(action: {
                            selectedTab = 0
                            showMenu = false
                        }) {
                            Label("Venues List", systemImage: "list.bullet")
                                .font(.title2)
                        }
                        Spacer()
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                    .frame(width: 220)
                    .background(Color(.systemBackground))
                    .edgesIgnoringSafeArea(.vertical)
                    .zIndex(2)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
        }
        .animation(.easeInOut, value: showMenu)
    }
}

// Restore VenueDetailView for showing venue details
struct VenueDetailView: View {
    let venue: Venue
    var onClose: (() -> Void)? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(venue.venuename)
                        .font(.custom("Kanit-Bold", size: 30))
                        .foregroundColor(.primaryOrange)
                    Spacer()
                    if let onClose = onClose {
                        Button(action: { onClose() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.appWhite)
                        }
                    }
                }
                if let slug = venue.slug, !slug.isEmpty {
                    Text("Slug: \(slug)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let fsa = venue.fsa_id {
                    Text("FSA ID: \(fsa)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let isLive = venue.is_live, !isLive.isEmpty {
                    Text("Live: \(isLive)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                Text(venue.address)
                    .foregroundColor(.appWhite)
                    .font(.custom("Kanit-Regular", size: 16))
                if let address2 = venue.address2, !address2.isEmpty {
                    Text(address2).foregroundColor(.appWhite).font(.custom("Kanit-Regular", size: 16))
                }
                Text("\(venue.town), \(venue.county), \(venue.postcode)")
                    .foregroundColor(.appWhite)
                    .font(.custom("Kanit-Regular", size: 16))
                if let postalsearch = venue.postalsearch, !postalsearch.isEmpty {
                    Text("Postal Search: \(postalsearch)").foregroundColor(.appWhite).font(.custom("Kanit-Regular", size: 16))
                }
                if let telephone = venue.telephone, !telephone.isEmpty {
                    Text("Tel: \(telephone)").foregroundColor(.appWhite).font(.custom("Kanit-Regular", size: 16))
                }
                if let website = venue.website, !website.isEmpty, website != "NULL" {
                    Link(website, destination: URL(string: website.hasPrefix("http") ? website : "https://\(website)")!)
                        .foregroundColor(.primaryOrange)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let photo = venue.photo, !photo.isEmpty, photo != "NULL" {
                    AsyncImage(url: URL(string: photo.hasPrefix("http") ? photo : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/\(photo)")) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxHeight: 200)
                }
                if let latStr = venue.latitude, let lonStr = venue.longitude,
                   let lat = Double(latStr), let lon = Double(lonStr) {
                    Map(position: .constant(.region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))) {
                        Annotation("Venue", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.primaryOrange)
                                .font(.title)
                        }
                    }
                    .frame(height: 250)
                } else {
                    Text("No map location available.").foregroundColor(.secondary).font(.custom("Kanit-Regular", size: 16))
                }
                Divider()
                if let venuetype = venue.venuetype, !venuetype.isEmpty {
                    Text("Type: \(venuetype)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let localAuth = venue.local_authority, !localAuth.isEmpty {
                    Text("Local Authority: \(localAuth)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let easting = venue.easting, !easting.isEmpty {
                    Text("Easting: \(easting)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let northing = venue.northing, !northing.isEmpty {
                    Text("Northing: \(northing)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let lat = venue.latitude, !lat.isEmpty {
                    Text("Latitude: \(lat)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let lon = venue.longitude, !lon.isEmpty {
                    Text("Longitude: \(lon)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let created = venue.created_at, !created.isEmpty {
                    Text("Created: \(created)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
                if let updated = venue.updated_at, !updated.isEmpty {
                    Text("Updated: \(updated)")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-Regular", size: 16))
                }
            }
            .padding()
            .font(.custom("Kanit-Regular", size: 20))
            .background(Color.secondaryBlue)
        }
        .background(Color.secondaryBlue)
    }
}

// Update EventDetailView to always fetch the full Venue from Supabase
struct EventDetailView: View {
    let event: EventWithVenue
    let onClose: (() -> Void)?
    @State private var venue: Venue? = nil
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(event.event_title)
                    .font(.custom("Kanit-Bold", size: 28))
                    .foregroundColor(.primaryOrange)
                Spacer()
                if let onClose = onClose {
                    Button(action: { onClose() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.appWhite)
                    }
                }
            }
            if let date = event.event_start {
                Text(date)
                    .font(.headline)
                    .foregroundColor(.appWhite)
            }
            if let venue = venue {
                Text("Venue: \(venue.venuename)")
                    .font(.subheadline)
                    .foregroundColor(.primaryOrange)
            } else if event.listingId != nil {
                Text("Venue: Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Venue: Unknown")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let desc = event.description, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.appWhite)
            }
            if let cost = event.cost, !cost.isEmpty {
                Text("Cost: £\(cost)")
                    .font(.body)
                    .foregroundColor(.appWhite)
            }
            if let duration = event.duration, !duration.isEmpty {
                Text("Duration: \(duration) mins")
                    .font(.body)
                    .foregroundColor(.appWhite)
            }
            if let website = event.website, !website.isEmpty {
                Link("Event Website", destination: URL(string: website.hasPrefix("http") ? website : "https://\(website)")!)
                    .foregroundColor(.primaryOrange)
            }
            if let photo = event.photo, !photo.isEmpty, photo != "NULL" {
                AsyncImage(url: URL(string: photo.hasPrefix("http") ? photo : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/event_images/\(photo)")) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 200)
            }
            Spacer()
        }
        .padding()
        .background(Color.secondaryBlue.ignoresSafeArea())
        .onAppear {
            fetchVenue()
        }
    }
    func fetchVenue() {
        guard let listingId = event.listingId else { return }
        Task {
            do {
                let response = try await client
                    .from("Venue")
                    .select("*")
                    .eq("id", value: listingId)
                    .single()
                    .execute()
                let decoded = try JSONDecoder().decode(Venue.self, from: response.data)
                DispatchQueue.main.async {
                    self.venue = decoded
                }
            } catch {
                print("Error fetching venue: \(error)")
            }
        }
    }
}

// Add this new subview for event rows
struct EventRowView: View {
    let event: Event
    let venue: Venue?
    let onVenueTap: (() -> Void)?
    let onEventTap: (() -> Void)?
    var photoURL: URL? {
        guard let photo = event.photo, !photo.isEmpty, photo != "NULL" else { return nil }
        let urlString: String
        if photo.hasPrefix("http") {
            urlString = photo
        } else {
            urlString = "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/event_images/\(photo)"
        }
        return URL(string: urlString)
    }
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let url = photoURL {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    Color.secondaryBlue
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            ProgressView()
                        )
                }
            }
            VStack(alignment: .leading) {
                Button(action: { onEventTap?() }) {
                    Text(event.event_title)
                        .font(.custom("Kanit-SemiBold", size: 24))
                        .foregroundColor(.primaryOrange)
                }
                if let date = event.event_start {
                    Text(date).font(.subheadline)
                        .foregroundColor(.appWhite)
                }
                if let venue = venue {
                    Button(action: { onVenueTap?() }) {
                        Text(venue.venuename)
                            .font(.caption)
                            .foregroundColor(.primaryOrange)
                            .underline()
                    }
                } else {
                    Text("Unknown Venue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let desc = event.description, !desc.isEmpty {
                    Text(desc).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryBlue)
    }
}

struct EventsListView: View {
    @State private var events: [EventWithVenue] = []
    @State private var page: Int = 0
    @State private var isLoading = false
    @State private var hasMore = true
    @Binding var selectedVenueFromEvent: Venue?
    @State private var userId: String? = nil
    @State private var userRole: String? = nil
    @State private var eventsLoaded = false
    @State private var selectedEvent: EventWithVenue? = nil
    let pageSize = 50
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    // Add event modal state
    @State private var showAddEventModal = false
    @State private var venueSearchText = ""
    @State private var venueSearchResults: [Venue] = []
    @State private var isVenueSearchLoading = false
    @State private var selectedVenueForEvent: Venue? = nil
    @State private var newEventTitle = ""
    @State private var newEventDate = ""
    @State private var newEventDescription = ""
    @State private var addEventError: String? = nil
    @State private var isAddingEvent = false
    @State private var cities: [City] = []
    @State private var categories: [Category] = []
    @State private var selectedCity: City? = nil
    @State private var selectedCategory: Category? = nil
    @State private var newEventCost: String = ""
    @State private var newEventDuration: String = ""
    @State private var newEventWebsite: String = ""
    @State private var newEventPhoto: String? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var newEventDateObj = Date()
    var body: some View {
        VStack {
            if userRole == "superadmin" || userRole == "venueadmin" {
                Button(action: { showAddEventModal = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryOrange)
                        Text("Add Event")
                            .font(.custom("Kanit-SemiBold", size: 20))
                            .foregroundColor(.primaryOrange)
                    }
                    .padding()
                    .background(Color.secondaryBlue)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            if isLoading || !eventsLoaded {
                ProgressView("Loading events and venues...")
            } else {
                List {
                    ForEach(events) { event in
                        VStack(spacing: 0) {
                            HStack(alignment: .center, spacing: 12) {
                                if let photo = event.photo, !photo.isEmpty, photo != "NULL" {
                                    AsyncImage(url: URL(string: photo.hasPrefix("http") ? photo : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/event_images/\(photo)")) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 48, height: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        case .failure(_):
                                            Color.secondaryBlue
                                                .frame(width: 48, height: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        case .empty:
                                            Color.secondaryBlue
                                                .frame(width: 48, height: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    ProgressView()
                                                )
                                        @unknown default:
                                            Color.secondaryBlue
                                                .frame(width: 48, height: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                                VStack(alignment: .leading) {
                                    Button(action: { selectedEvent = event }) {
                                        Text(event.event_title)
                                            .font(.custom("Kanit-SemiBold", size: 24))
                                            .foregroundColor(.primaryOrange)
                                    }
                                    if let date = event.event_start {
                                        Text(date).font(.subheadline)
                                            .foregroundColor(.appWhite)
                                    }
                                    if let venue = event.venue {
                                        Button(action: {
                                            // You may want to fetch the full Venue object if needed
                                            selectedVenueFromEvent = Venue(
                                                id: venue.id,
                                                fsa_id: nil,
                                                venuename: venue.venuename,
                                                slug: nil,
                                                venuetype: nil,
                                                address: "",
                                                address2: nil,
                                                town: "",
                                                county: "",
                                                postcode: "",
                                                postalsearch: nil,
                                                telephone: nil,
                                                easting: nil,
                                                northing: nil,
                                                latitude: nil,
                                                longitude: nil,
                                                local_authority: nil,
                                                website: nil,
                                                photo: nil,
                                                is_live: nil,
                                                created_at: nil,
                                                updated_at: nil
                                            )
                                        }) {
                                            Text(venue.venuename)
                                                .font(.caption)
                                                .foregroundColor(.primaryOrange)
                                                .underline()
                                        }
                                    } else {
                                        Text("Unknown Venue")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if let desc = event.description, !desc.isEmpty {
                                        Text(desc).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Divider()
                                .background(Color.primaryOrange)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.secondaryBlue)
                    }
                }
            }
            HStack {
                Button("Previous") {
                    if page > 0 {
                        page -= 1
                        fetchEventsWithVenue()
                    }
                }
                .disabled(page == 0 || isLoading)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.primaryOrange)
                .foregroundColor(.appWhite)
                .cornerRadius(8)
                .font(.custom("Kanit-SemiBold", size: 14))
                Spacer()
                // Page number in appWhite
                Text("Page \(page + 1)")
                    .foregroundColor(.appWhite)
                    .font(.custom("Kanit-SemiBold", size: 14))
                Spacer()
                Button("Next") {
                    if hasMore {
                        page += 1
                        fetchEventsWithVenue()
                    }
                }
                .disabled(!hasMore || isLoading)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.primaryOrange)
                .foregroundColor(.appWhite)
                .cornerRadius(8)
                .font(.custom("Kanit-SemiBold", size: 14))
            }
            .padding()
            .background(Color.darkBlue)
        }
        .onAppear {
            fetchEventsWithVenue()
            fetchUserAndRole()
            fetchCitiesAndCategories()
        }
        .font(.custom("Kanit-Regular", size: 20))
        .background(Color.secondaryBlue)
        .sheet(isPresented: $showAddEventModal) {
            NavigationView {
                VStack(spacing: 20) {
                    if let addEventError = addEventError {
                        Text("Error: \(addEventError)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.secondaryBlue)
                            .cornerRadius(8)
                    }
                    if selectedVenueForEvent == nil {
                        Text("Search for Venue")
                            .font(.custom("Kanit-Bold", size: 22))
                            .foregroundColor(.primaryOrange)
                        TextField("Type venue name...", text: $venueSearchText, onEditingChanged: { _ in }, onCommit: { searchVenues() })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: venueSearchText) { _ in searchVenues() }
                        if isVenueSearchLoading {
                            ProgressView()
                        } else {
                            List(venueSearchResults.prefix(100), id: \.id) { venue in
                                VStack(alignment: .leading) {
                                    Text(venue.venuename)
                                        .font(.custom("Kanit-SemiBold", size: 18))
                                        .foregroundColor(.primaryOrange)
                                    Text(venue.town)
                                        .font(.caption)
                                        .foregroundColor(.appWhite)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedVenueForEvent = venue
                                }
                                .listRowBackground(Color.secondaryBlue)
                            }
                        }
                    } else {
                        Text("Add Event for \(selectedVenueForEvent!.venuename)")
                            .font(.custom("Kanit-Bold", size: 22))
                            .foregroundColor(.primaryOrange)
                        TextField("Event Title", text: $newEventTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        DatePicker("Event Start", selection: $newEventDateObj, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                        TextField("Description", text: $newEventDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack(spacing: 12) {
                            TextField("Cost (e.g. 10.00)", text: $newEventCost)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Duration (minutes)", text: $newEventDuration)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("Select City")
                                    .font(.custom("Kanit-Bold", size: 18))
                                Picker("City", selection: $selectedCity) {
                                    ForEach(cities) { city in
                                        Text(city.name).tag(Optional(city))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .frame(maxWidth: .infinity)
                            VStack(alignment: .leading) {
                                Text("Select Category")
                                    .font(.custom("Kanit-Bold", size: 18))
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(categories) { category in
                                        Text(category.name).tag(Optional(category))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .frame(maxWidth: .infinity)
                        }
                        TextField("Website (optional)", text: $newEventWebsite)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack(spacing: 12) {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 48)
                                    .cornerRadius(8)
                            }
                            Button(selectedImage == nil ? "Select Photo" : "Change Photo") {
                                showImagePicker = true
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .font(.custom("Kanit-SemiBold", size: 14))
                            .background(Color.primaryOrange)
                            .foregroundColor(.appWhite)
                            .cornerRadius(8)
                            .frame(height: 32)
                        }
                        HStack {
                            Button("Cancel") {
                                resetAddEventForm()
                                showAddEventModal = false
                            }
                            .foregroundColor(.primaryOrange)
                            Spacer()
                            Button(isAddingEvent ? "Adding..." : "Add Event") {
                                addEvent()
                            }
                            .disabled(isAddingEvent || selectedCity == nil || selectedCategory == nil || newEventTitle.isEmpty || newEventDateObj == nil)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.primaryOrange)
                            .foregroundColor(.appWhite)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.appWhite.ignoresSafeArea())
                .navigationBarTitle(selectedVenueForEvent == nil ? "Select Venue" : "Add Event", displayMode: .inline)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, onClose: { selectedEvent = nil })
        }
    }
    func fetchEventsWithVenue() {
        isLoading = true
        hasMore = true
        events = []
        eventsLoaded = false
        Task {
            do {
                let from = page * pageSize
                let to = from + pageSize - 1
                let response = try await client
                    .from("Event")
                    .select("*, Venue(id, venuename)")
                    .order("event_start", ascending: true)
                    .range(from: from, to: to)
                    .execute()
                let decoded = try JSONDecoder().decode([EventWithVenue].self, from: response.data)
                DispatchQueue.main.async {
                    events = decoded
                    hasMore = decoded.count == pageSize
                    isLoading = false
                    eventsLoaded = true
                    print("[DEBUG] Events with venue loaded: \(events.count)")
                }
            } catch {
                print("[DEBUG] Error fetching events with venue: \(error)")
                DispatchQueue.main.async {
                    events = []
                    hasMore = false
                    isLoading = false
                    eventsLoaded = true
                }
            }
        }
    }
    func searchVenues() {
        guard !venueSearchText.isEmpty else {
            venueSearchResults = []
            return
        }
        isVenueSearchLoading = true
        Task {
            do {
                let response = try await client
                    .from("Venue")
                    .select()
                    .ilike("venuename", pattern: "%\(venueSearchText)%")
                    .limit(100)
                    .execute()
                let decoded = try JSONDecoder().decode([Venue].self, from: response.data)
                DispatchQueue.main.async {
                    venueSearchResults = decoded
                    isVenueSearchLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    venueSearchResults = []
                    isVenueSearchLoading = false
                }
            }
        }
    }
    func fetchCitiesAndCategories() {
        Task {
            do {
                let cityResponse = try await client.from("City").select().limit(100).execute()
                let decodedCities = try JSONDecoder().decode([City].self, from: cityResponse.data)
                cities = decodedCities
                let categoryResponse = try await client.from("Category").select().limit(100).execute()
                let decodedCategories = try JSONDecoder().decode([Category].self, from: categoryResponse.data)
                categories = decodedCategories
            } catch {
                print("Error fetching cities or categories: \(error)")
            }
        }
    }
    func fetchUserAndRole() {
        Task {
            do {
                let session = try await client.auth.session
                let user = session.user
                let userIdString = user.id.uuidString
                self.userId = userIdString
                // Fetch role from users table
                let response = try await client
                    .from("users")
                    .select("role")
                    .eq("id", value: userIdString)
                    .single()
                    .execute()
                if let data = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                   let role = data["role"] as? String {
                    DispatchQueue.main.async {
                        self.userRole = role
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.userRole = nil
                    self.userId = nil
                }
            }
        }
    }
    func addEvent() {
        guard let venue = selectedVenueForEvent, let city = selectedCity, let category = selectedCategory else { return }
        guard let userId = userId else {
            addEventError = "You must be signed in to add an event."
            isAddingEvent = false
            return
        }
        isAddingEvent = true
        addEventError = nil
        Task {
            do {
                var photoPath: String? = nil
                if let image = selectedImage {
                    // Upload image to Supabase Storage
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        let fileName = "public/event_\(UUID().uuidString).jpg"
                        let _ = try await client.storage.from("event_images").upload(path: fileName, file: data, options: FileOptions())
                        photoPath = fileName
                    }
                }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let eventStartString = formatter.string(from: newEventDateObj)
                let createdAtString = formatter.string(from: Date())
                let newEvent = NewEvent(
                    event_title: newEventTitle,
                    event_start: eventStartString,
                    description: newEventDescription,
                    listingId: venue.id,
                    cityId: city.id,
                    categoryId: category.id,
                    cost: newEventCost,
                    duration: newEventDuration.isEmpty ? nil : newEventDuration,
                    website: newEventWebsite.isEmpty ? "" : newEventWebsite,
                    photo: photoPath,
                    created_at: createdAtString,
                    user_id: userId
                )
                print("Attempting to add event with:")
                print("  event_title: \(newEventTitle)")
                print("  event_start: \(eventStartString)")
                print("  description: \(newEventDescription)")
                print("  listingId: \(venue.id)")
                print("  cityId: \(city.id)")
                print("  categoryId: \(category.id)")
                print("  cost: \(newEventCost)")
                print("  duration: \(newEventDuration)")
                print("  website: \(newEventWebsite)")
                print("  photo: \(photoPath ?? "nil")")
                print("  created_at: \(createdAtString)")
                print("  user_id: \(userId)")
                _ = try await client
                    .from("Event")
                    .insert([newEvent])
                    .execute()
                DispatchQueue.main.async {
                    isAddingEvent = false
                    showAddEventModal = false
                    resetAddEventForm()
                    fetchEventsWithVenue()
                }
            } catch {
                print("Error adding event: \(error)")
                DispatchQueue.main.async {
                    addEventError = error.localizedDescription
                    isAddingEvent = false
                }
            }
        }
    }
    func resetAddEventForm() {
        venueSearchText = ""
        venueSearchResults = []
        selectedVenueForEvent = nil
        newEventTitle = ""
        newEventDate = ""
        newEventDescription = ""
        addEventError = nil
        isAddingEvent = false
        selectedCity = nil
        selectedCategory = nil
        newEventCost = ""
        newEventDuration = ""
        newEventWebsite = ""
        newEventPhoto = nil
        selectedImage = nil
        newEventDateObj = Date()
    }
}

extension Venue: Equatable {
    static func == (lhs: Venue, rhs: Venue) -> Bool {
        lhs.id == rhs.id
    }
}

extension Venue: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Struct for inserting a new user row
struct NewUser: Encodable {
    let id: String
    let email: String
    let name: String
    let role: String
}

// Struct for inserting a new event row
struct NewEvent: Encodable {
    let event_title: String
    let event_start: String
    let description: String
    let listingId: Int
    let cityId: Int
    let categoryId: Int
    let cost: String?
    let duration: String?
    let website: String?
    let photo: String?
    let created_at: String
    let user_id: String
}

// DashboardView for authentication and user profile
struct DashboardView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var user: User? = nil
    @Binding var userRole: String?
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    var body: some View {
        VStack(spacing: 24) {
            if let user = user {
                VStack(spacing: 12) {
                    Text("Signed in as: \(user.email ?? "Unknown")")
                        .font(.custom("Kanit-SemiBold", size: 20))
                        .foregroundColor(.primaryOrange)
                    if let role = userRole {
                        Text("Role: \(role)")
                            .font(.custom("Kanit-Regular", size: 18))
                            .foregroundColor(.appWhite)
                    }
                    Button("Logout") {
                        logout()
                    }
                    .padding()
                    .background(Color.primaryOrange)
                    .foregroundColor(.appWhite)
                    .cornerRadius(8)
                }
                .padding()
                if userRole == "admin" {
                    Text("Admin Dashboard")
                        .font(.custom("Kanit-Bold", size: 24))
                        .foregroundColor(.primaryOrange)
                    // Add admin-only features here
                } else if userRole == "guest" {
                    Text("Guest Dashboard")
                        .font(.custom("Kanit-Bold", size: 24))
                        .foregroundColor(.primaryOrange)
                    // Add guest-only features here
                }
            } else {
                VStack(spacing: 16) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.custom("Kanit-Bold", size: 24))
                        .foregroundColor(.primaryOrange)
                    if isSignUp {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    Button(isSignUp ? "Sign Up" : "Sign In") {
                        isSignUp ? signUp() : signIn()
                    }
                    .padding()
                    .background(Color.primaryOrange)
                    .foregroundColor(.appWhite)
                    .cornerRadius(8)
                    Button(isSignUp ? "Have an account? Sign In" : "No account? Sign Up") {
                        isSignUp.toggle()
                    }
                    .foregroundColor(.primaryOrange)
                }
                .padding()
            }
        }
        .onAppear(perform: loadUser)
        .background(Color.darkBlue.ignoresSafeArea())
        .font(.custom("Kanit-Regular", size: 20))
    }
    func loadUser() {
        Task {
            do {
                let session = try await client.auth.session
                self.user = session.user
                fetchUserRole(userId: session.user.id.uuidString)
            } catch {
                self.user = nil
                self.userRole = nil
            }
        }
    }
    func signIn() {
        isLoading = true
        error = nil
        Task {
            do {
                let session = try await client.auth.signIn(email: email, password: password)
                DispatchQueue.main.async {
                    self.user = session.user
                    fetchUserRole(userId: session.user.id.uuidString)
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    func signUp() {
        isLoading = true
        error = nil
        Task {
            do {
                let session = try await client.auth.signUp(email: email, password: password)
                let user = session.user
                // Insert into users table
                let userName = name.isEmpty ? (user.email ?? "") : name
                let newUser = NewUser(id: user.id.uuidString, email: user.email ?? "", name: userName, role: "guest")
                _ = try await client
                    .from("users")
                    .insert([newUser])
                    .execute()
                DispatchQueue.main.async {
                    self.user = user
                    fetchUserRole(userId: user.id.uuidString)
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    func logout() {
        Task {
            do {
                try await client.auth.signOut()
                DispatchQueue.main.async {
                    self.user = nil
                    self.userRole = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    func fetchUserRole(userId: String) {
        Task {
            do {
                let response = try await client
                    .from("users")
                    .select("role")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                if let data = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                   let role = data["role"] as? String {
                    DispatchQueue.main.async {
                        self.userRole = role
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.userRole = nil
                }
            }
        }
    }
}

// Add ImagePicker for photo upload
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Add this subview to simplify the toolbar button
struct AddEventToolbarButton: View {
    let userRole: String?
    let action: () -> Void
    var body: some View {
        if userRole == "superadmin" || userRole == "venueadmin" {
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.primaryOrange)
            }
            .accessibilityLabel("Add Event")
        } else {
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
}
