//
//  ContentView.swift
//  PUBSUKx
//
//  Created by John Biddulph on 02/06/2025.
//

import SwiftUI
import Supabase
import MapKit

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

struct Event: Identifiable, Decodable {
    let id: Int
    let event_title: String
    let event_start: String?
    let description: String?
    let listingId: Int?
    let venue: Venue?
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
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                VenuesListView()
                    .navigationTitle("Venues")
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Venues")
                                .font(.custom("Kanit-Bold", size: 30))
                                .foregroundColor(.appWhite)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(Color.darkBlue)
            }
            .tabItem {
                Label {
                    Text("List").font(.custom("Kanit-SemiBold", size: 16))
                        .foregroundColor(selectedTab == 0 ? .primaryOrange : .appWhite.opacity(0.8))
                } icon: {
                    Image(systemName: "list.bullet")
                        .foregroundColor(selectedTab == 0 ? .primaryOrange : .appWhite.opacity(0.8))
                }
            }
            .tag(0)
            NavigationView {
                VenueMapView(selectedTab: $selectedTab)
                    .navigationTitle("Map")
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Map")
                                .font(.custom("Kanit-Bold", size: 30))
                                .foregroundColor(.appWhite)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(Color.appWhite)
            }
            .tabItem {
                Label {
                    Text("Map").font(.custom("Kanit-SemiBold", size: 16))
                        .foregroundColor(selectedTab == 1 ? .primaryOrange : .appWhite.opacity(0.8))
                } icon: {
                    Image(systemName: "map")
                        .foregroundColor(selectedTab == 1 ? .primaryOrange : .appWhite.opacity(0.8))
                }
            }
            .tag(1)
            NavigationView {
                EventsListView(selectedVenueFromEvent: $selectedVenueFromEvent)
                    .navigationTitle("Events")
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Events")
                                .font(.custom("Kanit-Bold", size: 30))
                                .foregroundColor(.appWhite)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(Color.darkBlue)
            }
            .tabItem {
                Label {
                    Text("Events").font(.custom("Kanit-SemiBold", size: 16))
                        .foregroundColor(selectedTab == 2 ? .primaryOrange : .appWhite.opacity(0.8))
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(selectedTab == 2 ? .primaryOrange : .appWhite.opacity(0.8))
                }
            }
            .tag(2)
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
                            Rectangle()
                                .fill(Color.primaryOrange)
                                .frame(height: 1)
                                .edgesIgnoringSafeArea(.horizontal)
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
                }
            } catch {
                DispatchQueue.main.async {
                    venues = []
                    hasMore = false
                    isLoading = false
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
            Color.appWhite.ignoresSafeArea()
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
                VenueDetailView(venue: venue)
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

struct VenueDetailView: View {
    let venue: Venue
    var onClose: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(venue.venuename)
                        .font(.custom("Kanit-Bold", size: 30))
                        .foregroundColor(.primaryOrange)
                    Group {
                        if let slug = venue.slug, !slug.isEmpty {
                            Text("Slug: \(slug)")
                        }
                        if let fsa = venue.fsa_id {
                            Text("FSA ID: \(fsa)")
                        }
                        if let isLive = venue.is_live, !isLive.isEmpty {
                            Text("Live: \(isLive)")
                        }
                    }
                    .font(.custom("Kanit-Regular", size: 20))
                    Text(venue.address)
                        .foregroundColor(.appWhite)
                    if let address2 = venue.address2, !address2.isEmpty {
                        Text(address2).foregroundColor(.appWhite)
                    }
                    Text("\(venue.town), \(venue.county), \(venue.postcode)")
                        .foregroundColor(.appWhite)
                    if let postalsearch = venue.postalsearch, !postalsearch.isEmpty {
                        Text("Postal Search: \(postalsearch)").foregroundColor(.appWhite)
                    }
                    if let telephone = venue.telephone, !telephone.isEmpty {
                        Text("Tel: \(telephone)").foregroundColor(.appWhite)
                    }
                    if let website = venue.website, !website.isEmpty, website != "NULL" {
                        Link(website, destination: URL(string: website.hasPrefix("http") ? website : "https://\(website)")!)
                            .foregroundColor(.primaryOrange)
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
                        Text("No map location available.").foregroundColor(.secondary)
                    }
                    Divider()
                    Group {
                        if let venuetype = venue.venuetype, !venuetype.isEmpty {
                            Text("Type: \(venuetype)")
                        }
                        if let localAuth = venue.local_authority, !localAuth.isEmpty {
                            Text("Local Authority: \(localAuth)")
                        }
                        if let easting = venue.easting, !easting.isEmpty {
                            Text("Easting: \(easting)")
                        }
                        if let northing = venue.northing, !northing.isEmpty {
                            Text("Northing: \(northing)")
                        }
                        if let lat = venue.latitude, !lat.isEmpty {
                            Text("Latitude: \(lat)")
                        }
                        if let lon = venue.longitude, !lon.isEmpty {
                            Text("Longitude: \(lon)")
                        }
                        if let created = venue.created_at, !created.isEmpty {
                            Text("Created: \(created)")
                        }
                        if let updated = venue.updated_at, !updated.isEmpty {
                            Text("Updated: \(updated)")
                        }
                    }
                    .font(.custom("Kanit-Regular", size: 20))
                }
                .padding()
                .font(.custom("Kanit-Regular", size: 20))
                .background(Color.secondaryBlue)
            }
            .font(.custom("Kanit-Regular", size: 20))
            .background(Color.secondaryBlue)
            if let onClose = onClose {
                Button(action: { onClose() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.appWhite)
                        .padding(16)
                }
            }
        }
    }
}

struct EventsListView: View {
    @State private var events: [Event] = []
    @State private var page: Int = 0
    @State private var isLoading = false
    @State private var hasMore = true
    @Binding var selectedVenueFromEvent: Venue?
    let pageSize = 50
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
                    ForEach(events) { event in
                        VStack(spacing: 0) {
                            VStack(alignment: .leading) {
                                Text(event.event_title)
                                    .font(.custom("Kanit-SemiBold", size: 24))
                                    .foregroundColor(.primaryOrange)
                                if let date = event.event_start {
                                    Text(date).font(.subheadline)
                                        .foregroundColor(.appWhite)
                                }
                                if let venue = event.venue {
                                    Button(action: { selectedVenueFromEvent = venue }) {
                                        Text("Venue: \(venue.venuename)")
                                            .font(.caption)
                                            .foregroundColor(.primaryOrange)
                                            .underline()
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                if let desc = event.description, !desc.isEmpty {
                                    Text(desc).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondaryBlue)
                            Rectangle()
                                .fill(Color.primaryOrange)
                                .frame(height: 1)
                                .edgesIgnoringSafeArea(.horizontal)
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
                        fetchEvents()
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
                        fetchEvents()
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
        .onAppear(perform: fetchEvents)
        .font(.custom("Kanit-Regular", size: 20))
        .background(Color.secondaryBlue)
    }
    func fetchEvents() {
        isLoading = true
        hasMore = true
        events = []
        Task {
            do {
                let from = page * pageSize
                let to = from + pageSize - 1
                let response = try await client
                    .from("Event")
                    .select("*, venue:Venue!Event_listingId_fkey(*)")
                    .order("event_start", ascending: true)
                    .range(from: from, to: to)
                    .execute()
                let decoded = try JSONDecoder().decode([Event].self, from: response.data)
                DispatchQueue.main.async {
                    events = decoded
                    hasMore = decoded.count == pageSize
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    events = []
                    hasMore = false
                    isLoading = false
                }
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

#Preview {
    ContentView()
}
