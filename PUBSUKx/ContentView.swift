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
    let cityId: Int?
    let categoryId: Int?
}

struct VenueSummary: Decodable {
    let id: Int
    let venuename: String
    let latitude: String?
    let longitude: String?
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

// Add this near the top of the file, after imports and before ContentView
struct DummyAnnotation: Identifiable { let id = UUID() }

struct EquatableCoordinateRegion: Equatable {
    var region: MKCoordinateRegion
    static func == (lhs: EquatableCoordinateRegion, rhs: EquatableCoordinateRegion) -> Bool {
        lhs.region.center.latitude == rhs.region.center.latitude &&
        lhs.region.center.longitude == rhs.region.center.longitude &&
        lhs.region.span.latitudeDelta == rhs.region.span.latitudeDelta &&
        lhs.region.span.longitudeDelta == rhs.region.span.longitudeDelta
    }
}

struct ContentView: View {
    @State private var selectedTab = 3 // Start on Dashboard tab
    @State private var selectedVenueFromEvent: Venue? = nil
    @State private var isDashboardPresented = false
    @State private var userRole: String? = nil
    @State private var showAddEventModal = false
    @State private var selectedVenueForEvent: Venue? = nil
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                if userRole == nil && selectedTab != 3 {
                    VStack {
                        Spacer()
                        ProgressView("Loading user profile...")
                        Spacer()
                    }
                    .background(Color.secondaryBlue)
                } else {
                    VenuesListView(
                        showAddEventModal: $showAddEventModal,
                        selectedVenueForEvent: $selectedVenueForEvent,
                        userRole: userRole
                    )
                    .navigationTitle("Venues")
                    .background(Color.darkBlue)
                }
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
                if userRole == nil && selectedTab != 3 {
                    VStack {
                        Spacer()
                        ProgressView("Loading user profile...")
                        Spacer()
                    }
                    .background(Color.secondaryBlue)
                } else {
                    VenueMapView(
                        selectedTab: $selectedTab,
                        showAddEventModal: $showAddEventModal,
                        selectedVenueForEvent: $selectedVenueForEvent,
                        userRole: userRole
                    )
                    .navigationTitle("Map")
                    .background(Color.darkBlue)
                }
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
                if userRole == nil && selectedTab != 3 {
                    VStack {
                        Spacer()
                        ProgressView("Loading user profile...")
                        Spacer()
                    }
                    .background(Color.secondaryBlue)
                } else {
                    EventsListView(selectedVenueFromEvent: $selectedVenueFromEvent)
                        .background(Color.darkBlue)
                }
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
            VenueDetailView(
                venue: venue,
                onClose: { selectedVenueFromEvent = nil },
                showAddEventModal: $showAddEventModal,
                selectedVenueForEvent: $selectedVenueForEvent,
                userRole: userRole
            )
        }
        .sheet(isPresented: $showAddEventModal) {
            AddEventModal(
                showAddEventModal: $showAddEventModal,
                selectedVenueForEvent: $selectedVenueForEvent
            )
        }
    }
}

// Move the existing list logic into VenuesListView
struct VenuesListView: View {
    @Binding var showAddEventModal: Bool
    @Binding var selectedVenueForEvent: Venue?
    var userRole: String?
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
    // Filter states
    @State private var showFilterMenu = false
    @State private var selectedCounty: String? = nil
    @State private var counties: [String] = []
    @State private var selectedTown: String? = nil
    @State private var towns: [String] = []
    @State private var isLiveFilter: Bool? = nil
    var body: some View {
        VStack {
            HStack {
                Spacer()
                if venues.count > 100 {
                    Button(action: { showFilterMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.primaryOrange)
                            .padding(8)
                    }
                }
            }
            .padding(.horizontal)
            // Add Clear Filter button if any filter is active
            if selectedCounty != nil || selectedTown != nil || isLiveFilter != nil {
                Button(action: {
                    selectedCounty = nil
                    selectedTown = nil
                    isLiveFilter = nil
                    towns = []
                    page = 0
                    fetchVenues()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear Filter")
                    }
                    .foregroundColor(.primaryOrange)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(Color.secondaryBlue)
                    .cornerRadius(8)
                }
                .padding(.bottom, 4)
            }
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
        .onAppear {
            fetchVenues()
            loadCounties()
        }
        .sheet(isPresented: $showFilterMenu) {
            NavigationView {
                Form {
                    Picker("County", selection: $selectedCounty) {
                        Text("Any").tag(nil as String?)
                        ForEach(counties, id: \.self) { county in
                            Text(county).tag(Optional(county))
                        }
                    }
                    .onChange(of: selectedCounty) { newCounty in
                        selectedTown = nil
                        page = 0 // Reset page when county changes
                        if let county = newCounty {
                            fetchTowns(for: county)
                        } else {
                            towns = []
                        }
                    }
                    if !towns.isEmpty {
                        Picker("Town", selection: $selectedTown) {
                            Text("Any").tag(nil as String?)
                            ForEach(towns, id: \.self) { town in
                                Text(town).tag(Optional(town))
                            }
                        }
                        .onChange(of: selectedTown) { _ in
                            page = 0 // Reset page when town changes
                        }
                    }
                    Section(header: Text("Live Status")) {
                        Toggle(isOn: Binding(
                            get: { isLiveFilter ?? false },
                            set: { newValue in isLiveFilter = newValue; page = 0 } // Reset page when live filter changes
                        )) {
                            Text("Show only live venues")
                        }
                        Button("Clear Live Filter") {
                            isLiveFilter = nil
                            page = 0 // Reset page when clearing live filter
                        }
                        .font(.caption)
                    }
                }
                .navigationBarTitle("Filter by County & Town", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Clear") {
                        selectedCounty = nil
                        selectedTown = nil
                        towns = []
                        isLiveFilter = nil
                        page = 0 // Reset page when clearing all filters
                    },
                    trailing: Button("Apply") {
                        showFilterMenu = false
                        page = 0 // Reset page when applying filters
                        fetchVenues()
                    }
                )
            }
        }
        .sheet(item: $selectedVenue) { venue in
            VenueDetailsModernView(venue: venue, userRole: userRole, onVenueUpdated: {
                fetchVenues()
            })
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
                var query = client
                    .from("Venue")
                    .select("*")
                if let county = selectedCounty {
                    query = query.eq("county", value: county)
                }
                if let town = selectedTown {
                    query = query.eq("town", value: town)
                }
                if let isLive = isLiveFilter {
                    query = query.eq("is_live", value: isLive ? "1" : "0")
                }
                let response = try await query
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
    func loadCounties() {
        // Load counties.json from the app bundle (no subdirectory)
        if let url = Bundle.main.url(forResource: "counties", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([String].self, from: data)
                counties = decoded.sorted()
            } catch {
                print("Failed to load counties.json: \(error)")
            }
        } else {
            print("counties.json not found in bundle")
        }
    }
    func fetchTowns(for county: String) {
        Task {
            do {
                let response = try await client
                    .from("Venue")
                    .select("town")
                    .eq("county", value: county)
                    .execute()
                let decoded = try JSONDecoder().decode([[String: String?]].self, from: response.data)
                let uniqueTowns = Set(decoded.compactMap { $0["town"] ?? nil }).filter { !$0.isEmpty }
                DispatchQueue.main.async {
                    towns = Array(uniqueTowns).sorted()
                }
            } catch {
                print("Failed to fetch towns: \(error)")
                towns = []
            }
        }
    }
}

// Placeholder for the new map view
struct VenueMapView: View {
    @StateObject private var viewModel = VenueMapViewModel()
    @State private var showMenu = false
    @Binding var selectedTab: Int
    @Binding var showAddEventModal: Bool
    @Binding var selectedVenueForEvent: Venue?
    var userRole: String?
    init(selectedTab: Binding<Int>, showAddEventModal: Binding<Bool>, selectedVenueForEvent: Binding<Venue?>, userRole: String?) {
        self._selectedTab = selectedTab
        self._showAddEventModal = showAddEventModal
        self._selectedVenueForEvent = selectedVenueForEvent
        self.userRole = userRole
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
                VenueDetailView(
                    venue: venue,
                    onClose: { viewModel.selectedVenue = nil },
                    showAddEventModal: $showAddEventModal,
                    selectedVenueForEvent: $selectedVenueForEvent,
                    userRole: userRole
                )
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
            // Loading progress overlay
            if viewModel.isLoading {
                VStack {
                    ProgressView(value: viewModel.loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal, 40)
                    Text("Loading venues… \(Int(viewModel.loadingProgress * 100))%")
                        .foregroundColor(.appWhite)
                        .font(.custom("Kanit-SemiBold", size: 16))
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .frame(maxWidth: 300)
            }
        }
        .animation(.easeInOut, value: showMenu)
    }
}

// Restore VenueDetailView for showing venue details
struct VenueDetailView: View {
    let venue: Venue
    var onClose: (() -> Void)? = nil
    @Binding var showAddEventModal: Bool
    @Binding var selectedVenueForEvent: Venue?
    var userRole: String?
    var onVenueUpdated: (() -> Void)? = nil
    @State private var showEditModal = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    var body: some View {
        if userRole == nil {
            VStack {
                ProgressView("Loading permissions...")
                Text("userRole: nil (waiting for permissions)")
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("userRole: \(userRole ?? "nil")") // DEBUG
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
                    if userRole == "superadmin" || userRole == "venueadmin" {
                        HStack(spacing: 16) {
                            Button("Edit") {
                                showEditModal = true
                            }
                            .padding()
                            .background(Color.primaryOrange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            Button("Delete") {
                                showDeleteConfirmation = true
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    Button(action: {
                        selectedVenueForEvent = venue
                        showAddEventModal = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.primaryOrange)
                            Text("Add Event")
                                .font(.custom("Kanit-SemiBold", size: 20))
                                .foregroundColor(.primaryOrange)
                        }
                        .padding(8)
                        .background(Color.secondaryBlue)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 8)
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
                        AsyncImage(
                            url: URL(string: photo.hasPrefix("http")
                                ? photo
                                : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/venue_images/\(photo)")
                        ) { image in
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
            .sheet(isPresented: $showEditModal) {
                VenueEditModal(venue: venue, onClose: { showEditModal = false }, onVenueUpdated: {
                    showEditModal = false
                    onVenueUpdated?()
                })
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Venue"),
                    message: Text("Are you sure you want to delete this venue? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteVenue()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    func deleteVenue() {
        guard !isDeleting else { return }
        isDeleting = true
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
        )
        Task {
            do {
                _ = try await client
                    .from("Venue")
                    .delete()
                    .eq("id", value: venue.id)
                    .execute()
                DispatchQueue.main.async {
                    isDeleting = false
                    onVenueUpdated?()
                    // Optionally, dismiss the view if presented modally
                }
            } catch {
                print("Error deleting venue: \(error)")
                DispatchQueue.main.async {
                    isDeleting = false
                }
            }
        }
    }
}

// Update EventDetailView to always fetch the full Venue from Supabase
struct EventDetailView: View {
    let event: EventWithVenue
    let userRole: String?
    let onClose: (() -> Void)?
    var onEventUpdated: (() -> Void)? = nil
    @State private var venue: Venue? = nil
    @State private var showEditModal = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var editFields: EventWithVenue? = nil
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    @State private var eventData: EventWithVenue? = nil
    // Computed property for displayEvent
    var displayEvent: EventWithVenue { eventData ?? event }
    // Computed properties for formatted date and time
    var eventDate: String {
        guard let start = displayEvent.event_start else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: start) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return dateFormatter.string(from: date)
        }
        return start
    }
    var eventTime: String {
        guard let start = displayEvent.event_start else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: start) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        }
        return ""
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(displayEvent.event_title)
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
            if !eventDate.isEmpty || !eventTime.isEmpty {
                HStack(spacing: 8) {
                    if !eventDate.isEmpty {
                        Text(eventDate)
                            .font(.headline)
                            .foregroundColor(.appWhite)
                    }
                    if !eventTime.isEmpty {
                        Text(eventTime)
                            .font(.headline)
                            .foregroundColor(.primaryOrange)
                    }
                }
            }
            if let venue = venue {
                Text("Venue: \(venue.venuename)")
                    .font(.subheadline)
                    .foregroundColor(.primaryOrange)
            } else if displayEvent.listingId != nil {
                Text("Venue: Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Venue: Unknown")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let desc = displayEvent.description, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.appWhite)
            }
            if let cost = displayEvent.cost, !cost.isEmpty {
                Text("Cost: £\(cost)")
                    .font(.body)
                    .foregroundColor(.appWhite)
            }
            if let duration = displayEvent.duration, !duration.isEmpty {
                Text("Duration: \(duration) mins")
                    .font(.body)
                    .foregroundColor(.appWhite)
            }
            if let website = displayEvent.website, !website.isEmpty {
                Link("Event Website", destination: URL(string: website.hasPrefix("http") ? website : "https://\(website)")!)
                    .foregroundColor(.primaryOrange)
            }
            if let photo = displayEvent.photo, !photo.isEmpty, photo != "NULL" {
                AsyncImage(url: URL(string: photo.hasPrefix("http") ? photo : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/event_images/\(photo)")) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 200)
            }
            if userRole == "superadmin" || userRole == "venueadmin" {
                HStack(spacing: 16) {
                    Button("Edit") {
                        editFields = displayEvent
                        showEditModal = true
                    }
                    .padding()
                    .background(Color.primaryOrange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    Button("Delete") {
                        showDeleteConfirmation = true
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.secondaryBlue.ignoresSafeArea())
        .onAppear { fetchVenue() }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Event"),
                message: Text("Are you sure you want to delete this event? This will also delete the event image from storage."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteEventAndImage()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showEditModal) {
            EditEventModal(event: displayEvent, venue: venue, onClose: {
                showEditModal = false
                fetchEventDetails()
                onEventUpdated?()
            })
        }
    }
    func fetchVenue() {
        guard let listingId = displayEvent.listingId else { return }
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
    func fetchEventDetails() {
        Task {
            do {
                let response = try await client
                    .from("Event")
                    .select("*, Venue(id, venuename), cityId, categoryId")
                    .eq("id", value: event.id)
                    .single()
                    .execute()
                let decoded = try JSONDecoder().decode(EventWithVenue.self, from: response.data)
                DispatchQueue.main.async {
                    self.eventData = decoded
                }
            } catch {
                print("Error fetching event details: \(error)")
            }
        }
    }
    func deleteEventAndImage() {
        guard !isDeleting else { return }
        isDeleting = true
        Task {
            do {
                // Delete image from storage if exists
                if let photo = displayEvent.photo, !photo.isEmpty, photo != "NULL" {
                    let fileName = photo.hasPrefix("http") ? URL(string: photo)?.lastPathComponent ?? photo : photo
                    try await client.storage.from("event_images").remove(paths: [fileName])
                }
                // Delete event from table
                _ = try await client
                    .from("Event")
                    .delete()
                    .eq("id", value: displayEvent.id)
                    .execute()
                DispatchQueue.main.async {
                    isDeleting = false
                    onClose?()
                }
            } catch {
                print("Error deleting event or image: \(error)")
                isDeleting = false
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
    // Filtering state for events
    @State private var showFilterMenu = false
    @State private var selectedCounty: String? = nil
    @State private var counties: [String] = []
    @State private var selectedTown: String? = nil
    @State private var towns: [String] = []
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
                }
                .cornerRadius(10)
                .padding(.top, 8)
            }
            HStack {
                Spacer()
                if events.count > 100 || selectedCounty != nil || selectedTown != nil {
                    Button(action: { showFilterMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.primaryOrange)
                            .padding(8)
                    }
                }
            }
            .padding(.horizontal)
            if isLoading || !eventsLoaded {
                ProgressView("Loading events and venues...")
            } else {
                List {
                    ForEach(events) { event in
                        VStack(spacing: 0) {
                            Button(action: { selectedEvent = event }) {
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
                                        Text(event.event_title)
                                            .font(.custom("Kanit-SemiBold", size: 24))
                                            .foregroundColor(.primaryOrange)
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
                            }
                            .buttonStyle(PlainButtonStyle())
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
            loadCounties()
        }
        .font(.custom("Kanit-Regular", size: 20))
        .background(Color.secondaryBlue)
        // Add the sheet for event details
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                userRole: userRole,
                onClose: { selectedEvent = nil }
            )
        }
        .sheet(isPresented: $showFilterMenu) {
            NavigationView {
                Form {
                    Picker("County", selection: $selectedCounty) {
                        Text("Any").tag(nil as String?)
                        ForEach(counties, id: \.self) { county in
                            Text(county).tag(Optional(county))
                        }
                    }
                    .onChange(of: selectedCounty) { newCounty in
                        selectedTown = nil
                        page = 0 // Reset page when county changes
                        if let county = newCounty {
                            fetchTowns(for: county)
                        } else {
                            towns = []
                        }
                    }
                    if !towns.isEmpty {
                        Picker("Town", selection: $selectedTown) {
                            Text("Any").tag(nil as String?)
                            ForEach(towns, id: \.self) { town in
                                Text(town).tag(Optional(town))
                            }
                        }
                        .onChange(of: selectedTown) { _ in
                            page = 0 // Reset page when town changes
                        }
                    }
                }
                .navigationBarTitle("Filter by County & Town", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Clear") {
                        selectedCounty = nil
                        selectedTown = nil
                        towns = []
                        page = 0 // Reset page when clearing all filters
                    },
                    trailing: Button("Apply") {
                        showFilterMenu = false
                        page = 0 // Reset page when applying filters
                        fetchEventsWithVenue()
                    }
                )
            }
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
                var query = client
                    .from("Event")
                    .select("*, Venue(id, venuename, county, town), cityId, categoryId")
                if let county = selectedCounty {
                    query = query.eq("Venue.county", value: county)
                }
                if let town = selectedTown {
                    query = query.eq("Venue.town", value: town)
                }
                let response = try await query
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
    func loadCounties() {
        Task {
            do {
                let response = try await client
                    .from("Venue")
                    .select("county")
                    .execute()
                let decoded = try JSONDecoder().decode([[String: String?]].self, from: response.data)
                let uniqueCounties = Set(decoded.compactMap { $0["county"] ?? nil }).filter { !$0.isEmpty }
                DispatchQueue.main.async {
                    counties = Array(uniqueCounties).sorted()
                }
            } catch {
                print("Failed to load counties for events: \(error)")
            }
        }
    }
    func fetchTowns(for county: String) {
        Task {
            do {
                let response = try await client
                    .from("Venue")
                    .select("town")
                    .eq("county", value: county)
                    .execute()
                let decoded = try JSONDecoder().decode([[String: String?]].self, from: response.data)
                let uniqueTowns = Set(decoded.compactMap { $0["town"] ?? nil }).filter { !$0.isEmpty }
                DispatchQueue.main.async {
                    towns = Array(uniqueTowns).sorted()
                }
            } catch {
                print("Failed to fetch towns for events: \(error)")
                towns = []
            }
        }
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
    @State private var debugLog: String = ""
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
            Spacer()
            ScrollView {
                Text(debugLog)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
        }
        .onAppear {
            debugLog.append("DashboardView appeared\n")
            loadUser()
        }
        .background(Color.darkBlue.ignoresSafeArea())
        .font(.custom("Kanit-Regular", size: 20))
    }
    func loadUser() {
        Task {
            do {
                debugLog.append("Trying to load user session\n")
                let session = try await client.auth.session
                debugLog.append("Loaded session: \(session)\n")
                self.user = session.user
                fetchUserRole(userId: session.user.id.uuidString)
            } catch {
                debugLog.append("Failed to load user: \(error)\n")
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
                debugLog.append("Signed in, session: \(session)\n")
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
                debugLog.append("Signed up, session: \(session)\n")
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
                debugLog.append("Logged out\n")
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
                debugLog.append("Fetching user role for id: \(userId)\n")
                let response = try await client
                    .from("users")
                    .select("role")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                debugLog.append("User role response: \(String(data: response.data, encoding: .utf8) ?? "nil")\n")
                if let data = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                   let role = data["role"] as? String {
                    debugLog.append("Fetched user role: \(role)\n")
                    DispatchQueue.main.async {
                        self.userRole = role
                    }
                } else {
                    debugLog.append("Role not found in response\n")
                }
            } catch {
                debugLog.append("Failed to fetch user role: \(error)\n")
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

// Replace EditEventModal with a full-featured version:
struct EditEventModal: View {
    let event: EventWithVenue
    let venue: Venue?
    let onClose: () -> Void
    @State private var eventTitle: String
    @State private var eventDescription: String
    @State private var eventCost: String
    @State private var eventDuration: String
    @State private var eventWebsite: String
    @State private var eventStart: Date
    @State private var selectedCity: City? = nil
    @State private var selectedCategory: Category? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var photoPath: String?
    @State private var isSaving = false
    @State private var cities: [City] = []
    @State private var categories: [Category] = []
    @State private var showImagePicker = false
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    init(event: EventWithVenue, venue: Venue?, onClose: @escaping () -> Void) {
        self.event = event
        self.venue = venue
        self.onClose = onClose
        _eventTitle = State(initialValue: event.event_title)
        _eventDescription = State(initialValue: event.description ?? "")
        _eventCost = State(initialValue: event.cost ?? "")
        _eventDuration = State(initialValue: event.duration ?? "")
        _eventWebsite = State(initialValue: event.website ?? "")
        // Robust event_start parsing
        if let start = event.event_start {
            print("[DEBUG] event.event_start raw: \(start)")
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: start) {
                print("[DEBUG] Parsed with ISO8601DateFormatter")
                _eventStart = State(initialValue: date)
            } else {
                let fmts = [
                    "yyyy-MM-dd'T'HH:mm:ss",
                    "yyyy-MM-dd HH:mm:ss",
                    "yyyy-MM-dd'T'HH:mm",
                    "yyyy-MM-dd HH:mm"
                ]
                var found: Date? = nil
                for fmt in fmts {
                    let df = DateFormatter()
                    df.dateFormat = fmt
                    df.locale = Locale(identifier: "en_US_POSIX")
                    if let d = df.date(from: start) {
                        print("[DEBUG] Parsed with format: \(fmt)")
                        found = d
                        break
                    }
                }
                if let d = found {
                    _eventStart = State(initialValue: d)
                } else {
                    print("[DEBUG] Could not parse event_start, using current date")
                    _eventStart = State(initialValue: Date())
                }
            }
        } else {
            _eventStart = State(initialValue: Date())
        }
        _photoPath = State(initialValue: event.photo)
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $eventTitle)
                    TextField("Description", text: $eventDescription)
                    TextField("Cost", text: $eventCost)
                    TextField("Duration", text: $eventDuration)
                    DatePicker("Event Start", selection: $eventStart, displayedComponents: [.date, .hourAndMinute])
                    TextField("Website", text: $eventWebsite)
                }
                Section(header: Text("City & Category")) {
                    Picker("City", selection: $selectedCity) {
                        Text("Select a city").tag(nil as City?)
                        ForEach(cities) { city in
                            Text(city.name).tag(Optional(city))
                        }
                    }
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select a category").tag(nil as Category?)
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category))
                        }
                    }
                }
                Section(header: Text("Photo")) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(8)
                    } else if let photo = photoPath, !photo.isEmpty, photo != "NULL" {
                        AsyncImage(url: URL(string: photo.hasPrefix("http") ? photo : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/event_images/\(photo)")) { image in
                            image.resizable().scaledToFit().frame(height: 120).cornerRadius(8)
                        } placeholder: {
                            ProgressView().frame(height: 120)
                        }
                    }
                    Button(selectedImage == nil ? "Select Photo" : "Change Photo") {
                        showImagePicker = true
                    }
                }
                Button(isSaving ? "Saving..." : "Save Changes") {
                    saveChanges()
                }
                .disabled(isSaving || selectedCity == nil || selectedCategory == nil || eventTitle.isEmpty)
                .foregroundColor(.white)
                .padding()
                .background(Color.primaryOrange)
                .cornerRadius(8)
            }
            .navigationBarTitle("Edit Event", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { onClose() })
            .onAppear(perform: fetchCitiesAndCategories)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    func fetchCitiesAndCategories() {
        Task {
            do {
                let cityResponse = try await client.from("City").select().limit(100).execute()
                let decodedCities = try JSONDecoder().decode([City].self, from: cityResponse.data)
                cities = decodedCities
                if let cityId = event.cityId, let found = decodedCities.first(where: { $0.id == cityId }) {
                    selectedCity = found
                }
                let categoryResponse = try await client.from("Category").select().limit(100).execute()
                let decodedCategories = try JSONDecoder().decode([Category].self, from: categoryResponse.data)
                categories = decodedCategories
                if let catId = event.categoryId, let found = decodedCategories.first(where: { $0.id == catId }) {
                    selectedCategory = found
                }
            } catch {
                print("Error fetching cities or categories: \(error)")
            }
        }
    }
    func saveChanges() {
        isSaving = true
        Task {
            do {
                var newPhotoPath = photoPath // Always start with the current photo path
                // If a new image is selected, upload it and update newPhotoPath
                if let image = selectedImage {
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        // Delete old image if exists
                        if let oldPhoto = photoPath, !oldPhoto.isEmpty, oldPhoto != "NULL" {
                            let fileName = oldPhoto.hasPrefix("http") ? URL(string: oldPhoto)?.lastPathComponent ?? oldPhoto : oldPhoto
                            try await client.storage.from("event_images").remove(paths: [fileName])
                        }
                        let fileName = "public/event_\(UUID().uuidString).jpg"
                        let _ = try await client.storage.from("event_images").upload(path: fileName, file: data, options: FileOptions())
                        newPhotoPath = fileName
                    }
                }
                print("[DEBUG] Final photo path for update: \(String(describing: newPhotoPath))")
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let eventStartString = formatter.string(from: eventStart)
                struct EventUpdate: Encodable {
                    let event_title: String
                    let event_start: String
                    let description: String
                    let cost: String
                    let duration: String?
                    let website: String?
                    let photo: String?
                    let cityId: Int
                    let categoryId: Int
                }
                let updatePayload = EventUpdate(
                    event_title: eventTitle,
                    event_start: eventStartString,
                    description: eventDescription,
                    cost: eventCost,
                    duration: eventDuration.isEmpty ? nil : eventDuration,
                    website: eventWebsite.isEmpty ? nil : eventWebsite,
                    photo: newPhotoPath, // always set to current or new
                    cityId: selectedCity?.id ?? 0,
                    categoryId: selectedCategory?.id ?? 0
                )
                print("[DEBUG] Update payload: \(updatePayload)")
                let response = try await client
                    .from("Event")
                    .update(updatePayload)
                    .eq("id", value: event.id)
                    .execute()
                print("[DEBUG] Supabase update response: \(response)")
                DispatchQueue.main.async {
                    isSaving = false
                    onClose()
                }
            } catch {
                print("[DEBUG] Error updating event: \(error)")
                isSaving = false
            }
        }
    }
}

// 1. Extract AddEventModal from EventsListView
struct AddEventModal: View {
    @Binding var showAddEventModal: Bool
    @Binding var selectedVenueForEvent: Venue?
    @State private var venueSearchText = ""
    @State private var venueSearchResults: [Venue] = []
    @State private var isVenueSearchLoading = false
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
    @State private var userId: String? = nil
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    var body: some View {
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
                        List(venueSearchResults.prefix(100), id: \ .id) { venue in
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
                                Text("Select a city").tag(nil as City?)
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
                                Text("Select a category").tag(nil as Category?)
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
        .onAppear {
            fetchUserAndRole()
            fetchCitiesAndCategories()
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
            } catch {
                self.userId = nil
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
                _ = try await client
                    .from("Event")
                    .insert([newEvent])
                    .execute()
                DispatchQueue.main.async {
                    isAddingEvent = false
                    showAddEventModal = false
                    resetAddEventForm()
                }
            } catch {
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

#Preview {
    ContentView()
}

// VenueEditModal for editing venue details
struct VenueEditModal: View {
    let venue: Venue
    let onClose: () -> Void
    let onVenueUpdated: (() -> Void)?
    @State private var fsa_id: String
    @State private var venuename: String
    @State private var slug: String
    @State private var venuetype: String
    @State private var address: String
    @State private var address2: String
    @State private var town: String
    @State private var county: String
    @State private var postcode: String
    @State private var postalsearch: String
    @State private var telephone: String
    @State private var easting: String
    @State private var northing: String
    @State private var latitude: String
    @State private var longitude: String
    @State private var local_authority: String
    @State private var website: String
    @State private var photo: String
    @State private var is_live: String
    @State private var updated_at: String
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var saveError: String? = nil
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
    )
    @State private var equatableRegion: EquatableCoordinateRegion
    init(venue: Venue, onClose: @escaping () -> Void, onVenueUpdated: (() -> Void)? = nil) {
        self.venue = venue
        self.onClose = onClose
        self.onVenueUpdated = onVenueUpdated
        _fsa_id = State(initialValue: venue.fsa_id.map { String($0) } ?? "")
        _venuename = State(initialValue: venue.venuename)
        _slug = State(initialValue: venue.slug ?? "")
        _venuetype = State(initialValue: venue.venuetype ?? "")
        _address = State(initialValue: venue.address)
        _address2 = State(initialValue: venue.address2 ?? "")
        _town = State(initialValue: venue.town)
        _county = State(initialValue: venue.county)
        _postcode = State(initialValue: venue.postcode)
        _postalsearch = State(initialValue: venue.postalsearch ?? "")
        _telephone = State(initialValue: venue.telephone ?? "")
        _easting = State(initialValue: venue.easting ?? "")
        _northing = State(initialValue: venue.northing ?? "")
        _latitude = State(initialValue: venue.latitude ?? "")
        _longitude = State(initialValue: venue.longitude ?? "")
        _local_authority = State(initialValue: venue.local_authority ?? "")
        _website = State(initialValue: venue.website ?? "")
        _photo = State(initialValue: venue.photo ?? "")
        _is_live = State(initialValue: venue.is_live ?? "")
        _updated_at = State(initialValue: venue.updated_at ?? "")
        let lat = Double(venue.latitude ?? "") ?? 51.5074
        let lon = Double(venue.longitude ?? "") ?? -0.1278
        _equatableRegion = State(initialValue: EquatableCoordinateRegion(region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
    var photoURL: URL? {
        if photo.isEmpty { return nil }
        if photo.hasPrefix("http") {
            return URL(string: photo)
        } else {
            return URL(string: "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/venue_images/\(photo)")
        }
    }
    var body: some View {
        NavigationView {
            Form {
                if let saveError = saveError {
                    Text("Error: \(saveError)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom, 4)
                }
                Section(header: Text("Venue Details")) {
                    TextField("FSA ID", text: $fsa_id)
                        .keyboardType(.numberPad)
                    TextField("Venue Name", text: $venuename)
                    TextField("Slug", text: $slug)
                    TextField("Type", text: $venuetype)
                    TextField("Address", text: $address)
                    TextField("Address 2", text: $address2)
                    TextField("Town", text: $town)
                    TextField("County", text: $county)
                    TextField("Postcode", text: $postcode)
                    TextField("Postal Search", text: $postalsearch)
                    TextField("Telephone", text: $telephone)
                    TextField("Easting", text: $easting)
                    TextField("Northing", text: $northing)
                    TextField("Latitude", text: $latitude)
                    TextField("Longitude", text: $longitude)
                    TextField("Local Authority", text: $local_authority)
                    TextField("Website", text: $website)
                    TextField("Is Live", text: $is_live)
                }
                Section(header: Text("Photo")) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(8)
                    } else if let url = photoURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit().frame(height: 120).cornerRadius(8)
                        } placeholder: {
                            ProgressView().frame(height: 120)
                        }
                    }
                    Button(selectedImage == nil ? "Select Photo" : "Change Photo") {
                        showImagePicker = true
                    }
                }
                Button(isSaving ? "Saving..." : "Save Changes") {
                    saveChanges()
                }
                .disabled(isSaving || venuename.isEmpty || address.isEmpty || town.isEmpty || county.isEmpty || postcode.isEmpty)
                .foregroundColor(.white)
                .padding()
                .background(Color.primaryOrange)
                .cornerRadius(8)
                if isSaving {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                Section {
                    TextField("Latitude", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitude)
                        .keyboardType(.decimalPad)
                    ZStack {
                        Map(coordinateRegion: $equatableRegion.region, interactionModes: .all, showsUserLocation: false)
                            .frame(height: 200)
                            .cornerRadius(12)
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primaryOrange)
                            .background(Circle().fill(Color.white.opacity(0.7)).frame(width: 40, height: 40))
                    }
                    .onChange(of: equatableRegion) { newEquatableRegion in
                        let newCenter = newEquatableRegion.region.center
                        latitude = String(format: "%.6f", newCenter.latitude)
                        longitude = String(format: "%.6f", newCenter.longitude)
                    }
                    Text("Move the map so the crosshair is over the venue location.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Latitude & Longitude")
                }
            }
            .navigationBarTitle("Edit Venue", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { onClose() })
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    func saveChanges() {
        isSaving = true
        saveError = nil
        Task {
            do {
                var photoPath = photo
                if let image = selectedImage, let data = image.jpegData(compressionQuality: 0.8) {
                    let fileName = "public/venue_\(UUID().uuidString).jpg"
                    let _ = try await client.storage.from("venue_images").upload(path: fileName, file: data, options: FileOptions())
                    photoPath = fileName
                }
                struct VenueUpdate: Encodable {
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
                    let updated_at: String
                }
                let updatePayload = VenueUpdate(
                    fsa_id: fsa_id.isEmpty ? nil : Int(fsa_id),
                    venuename: venuename,
                    slug: slug.isEmpty ? nil : slug,
                    venuetype: venuetype.isEmpty ? nil : venuetype,
                    address: address,
                    address2: address2.isEmpty ? nil : address2,
                    town: town,
                    county: county,
                    postcode: postcode,
                    postalsearch: postalsearch.isEmpty ? nil : postalsearch,
                    telephone: telephone.isEmpty ? nil : telephone,
                    easting: easting.isEmpty ? nil : easting,
                    northing: northing.isEmpty ? nil : northing,
                    latitude: latitude.isEmpty ? nil : latitude,
                    longitude: longitude.isEmpty ? nil : longitude,
                    local_authority: local_authority.isEmpty ? nil : local_authority,
                    website: website.isEmpty ? nil : website,
                    photo: photoPath.isEmpty ? nil : photoPath,
                    is_live: is_live.isEmpty ? nil : is_live,
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                let _ = try await client
                    .from("Venue")
                    .update(updatePayload)
                    .eq("id", value: venue.id)
                    .execute()
                DispatchQueue.main.async {
                    isSaving = false
                    onVenueUpdated?()
                    onClose()
                }
            } catch {
                DispatchQueue.main.async {
                    saveError = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

// Modern Venue Details View styled after the Tomorrowland design
struct VenueDetailsModernView: View {
    let venue: Venue
    var userRole: String? = nil
    @State private var showEditModal = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    var onVenueUpdated: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.secondaryBlue.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image with venue name overlay
                    if let photo = venue.photo, !photo.isEmpty, photo != "NULL" {
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(
                                url: URL(string: photo.hasPrefix("http")
                                    ? photo
                                    : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/venue_images/\(photo)")
                            ) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .clipped()
                            } placeholder: {
                                Color.darkBlue.frame(height: 220)
                            }
                            // Gradient overlay at bottom
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                                startPoint: .bottom, endPoint: .top
                            )
                            .frame(height: 80)
                            .frame(maxWidth: .infinity, alignment: .bottom)
                            // Venue name overlay
                            HStack {
                                Text(venue.venuename)
                                    .font(.custom("Kanit-Bold", size: 28))
                                    .foregroundColor(.appWhite)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(10)
                                    .padding([.leading, .bottom], 16)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .bottomLeading)
                        }
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        // Edit/Delete buttons for admin roles
                        if userRole == "superadmin" || userRole == "venueadmin" {
                            HStack(spacing: 16) {
                                Button("Edit") {
                                    showEditModal = true
                                }
                                .padding()
                                .background(Color.primaryOrange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                Button("Delete") {
                                    showDeleteConfirmation = true
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.custom("Kanit-SemiBold", size: 18))
                                .foregroundColor(.primaryOrange)
                            Text(venue.address)
                                .foregroundColor(.appWhite)
                                .font(.custom("Kanit-Regular", size: 16))
                            if let desc = venue.venuetype, !desc.isEmpty {
                                Text(desc)
                                    .foregroundColor(.appWhite)
                                    .font(.custom("Kanit-Regular", size: 16))
                            }
                        }

                        // Map
                        if let latStr = venue.latitude, let lonStr = venue.longitude,
                           let lat = Double(latStr), let lon = Double(lonStr) {
                            Map(
                                position: .constant(.region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )))
                            ) {
                                Annotation(venue.venuename, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.primaryOrange)
                                        .font(.title)
                                }
                            }
                            .frame(height: 120)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primaryOrange, lineWidth: 2)
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            // Sheet and alert for edit/delete actions
            .sheet(isPresented: $showEditModal) {
                VenueEditModal(venue: venue, onClose: { showEditModal = false }, onVenueUpdated: {
                    showEditModal = false
                    onVenueUpdated?()
                })
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Venue"),
                    message: Text("Are you sure you want to delete this venue? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteVenue()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    func deleteVenue() {
        guard !isDeleting else { return }
        isDeleting = true
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://isprmebbahzjnrekkvxv.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzcHJtZWJiYWh6am5yZWtrdnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDgxMTcxOTQsImV4cCI6MjAyMzY5MzE5NH0.KQTIMSGTyNruxx1VQw8cY67ipbh1mABhjJ9tIhxClHE"
        )
        Task {
            do {
                _ = try await client
                    .from("Venue")
                    .delete()
                    .eq("id", value: venue.id)
                    .execute()
                DispatchQueue.main.async {
                    isDeleting = false
                    onVenueUpdated?()
                    // Optionally, dismiss the view if presented modally
                }
            } catch {
                print("Error deleting venue: \(error)")
                DispatchQueue.main.async {
                    isDeleting = false
                }
            }
        }
    }
}

// Modern Event Details View styled after the Tomorrowland design
struct EventDetailsModernView: View {
    let event: EventWithVenue

    var eventDate: String {
        guard let start = event.event_start else { return "" }
        let parts = start.components(separatedBy: ["T", " "])
        return parts.first ?? ""
    }
    var eventTime: String {
        guard let start = event.event_start else { return "" }
        let parts = start.components(separatedBy: ["T", " "])
        if parts.count > 1 {
            return parts[1].prefix(5).description // HH:mm
        }
        return ""
    }

    var body: some View {
        ZStack {
            Color.secondaryBlue.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image
                    if let photo = event.photo, !photo.isEmpty, photo != "NULL" {
                        AsyncImage(
                            url: URL(string: photo.hasPrefix("http")
                                ? photo
                                : "https://isprmebbahzjnrekkvxv.supabase.co/storage/v1/object/public/event_images/\(photo)")
                        ) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .clipped()
                        } placeholder: {
                            Color.darkBlue.frame(height: 220)
                        }
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        // Event Name
                        Text(event.event_title)
                            .font(.custom("Kanit-Bold", size: 32))
                            .foregroundColor(.appWhite)
                            .padding(.top, 8)

                        // Date and Time
                        HStack(spacing: 18) {
                            if !eventDate.isEmpty {
                                Label(eventDate, systemImage: "calendar")
                                    .foregroundColor(.appWhite)
                                    .font(.custom("Kanit-Regular", size: 16))
                            }
                            if !eventTime.isEmpty {
                                Label(eventTime, systemImage: "clock")
                                    .foregroundColor(.appWhite)
                                    .font(.custom("Kanit-Regular", size: 16))
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.custom("Kanit-SemiBold", size: 18))
                                .foregroundColor(.primaryOrange)
                            if let desc = event.description, !desc.isEmpty {
                                Text(desc)
                                    .foregroundColor(.appWhite)
                                    .font(.custom("Kanit-Regular", size: 16))
                            }
                        }

                        // Map
                        if let venue = event.venue, let latStr = venue.latitude, let lonStr = venue.longitude,
                           let lat = Double(latStr), let lon = Double(lonStr) {
                            Map(
                                position: .constant(.region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )))
                            ) {
                                Annotation(venue.venuename, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.primaryOrange)
                                        .font(.title)
                                }
                            }
                            .frame(height: 120)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primaryOrange, lineWidth: 2)
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }
}

// Helper for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

