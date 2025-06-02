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
    let venuename: String
    let address: String
    let town: String
    let county: String
    let postcode: String
    let website: String?
    let photo: String?
    let latitude: String?
    let longitude: String?
    let venuetype: String?
}

struct ContentView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                VenuesListView()
                    .navigationTitle("Venues")
            }
            .tabItem {
                Label("List", systemImage: "list.bullet")
            }
            .tag(0)
            NavigationView {
                VenueMapView(selectedTab: $selectedTab)
                    .navigationTitle("Map")
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            .tag(1)
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
                List(venues) { venue in
                    Button(action: { selectedVenue = venue }) {
                        VStack(alignment: .leading) {
                            Text(venue.venuename).font(.headline)
                            Text(venue.address)
                            Text("\(venue.town), \(venue.county), \(venue.postcode)")
                            if let website = venue.website, !website.isEmpty, website != "NULL" {
                                Text(website).foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            HStack {
                Button("Previous") {
                    if page > 0 {
                        page -= 1
                        fetchVenues()
                    }
                }.disabled(page == 0 || isLoading)
                Spacer()
                Button("Next") {
                    if hasMore {
                        page += 1
                        fetchVenues()
                    }
                }.disabled(!hasMore || isLoading)
            }
            .padding()
        }
        .onAppear(perform: fetchVenues)
        .sheet(item: $selectedVenue) { venue in
            VenueDetailView(venue: venue)
        }
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(venue.venuename).font(.largeTitle).bold()
                Text(venue.address)
                Text("\(venue.town), \(venue.county), \(venue.postcode)")
                if let website = venue.website, !website.isEmpty, website != "NULL" {
                    Link(website, destination: URL(string: website.hasPrefix("http") ? website : "https://\(website)")!)
                        .foregroundColor(.blue)
                }
                if let photo = venue.photo, !photo.isEmpty, photo != "NULL" {
                    // You may want to adjust the image URL logic for your storage
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
                                .foregroundColor(.red)
                                .font(.title)
                        }
                    }
                    .frame(height: 250)
                } else {
                    Text("No map location available.").foregroundColor(.secondary)
                }
                Divider()
                Group {
                    Text("Type: \(venue.venuetype ?? "N/A")")
                    Text("Local Authority: N/A")
                    Text("Created: N/A")
                    Text("Updated: N/A")
                }
            }
            .padding()
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
