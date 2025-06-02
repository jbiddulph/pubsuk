import SwiftUI
import MapKit

struct ClusteredVenueMapView: UIViewRepresentable {
    @ObservedObject var viewModel: VenueMapViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(MKPointAnnotation.self))
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(MKClusterAnnotation.self))
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Only update markers in regionDidChangeAnimated
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ClusteredVenueMapView
        init(_ parent: ClusteredVenueMapView) {
            self.parent = parent
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let identifier: String
            if annotation is MKClusterAnnotation {
                identifier = NSStringFromClass(MKClusterAnnotation.self)
            } else {
                identifier = NSStringFromClass(MKPointAnnotation.self)
            }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation) as? MKMarkerAnnotationView
            view?.canShowCallout = true
            view?.clusteringIdentifier = "venue"
            view?.markerTintColor = .systemRed
            return view
        }
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKPointAnnotation,
                  let title = annotation.title else { return }
            if let venue = parent.viewModel.allVenues.first(where: { v in
                v.venuename == title &&
                Double(v.latitude ?? "") == annotation.coordinate.latitude &&
                Double(v.longitude ?? "") == annotation.coordinate.longitude
            }) {
                DispatchQueue.main.async {
                    self.parent.viewModel.selectedVenue = venue
                }
            }
        }
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.viewModel.regionDidChange(mapView.region)
            mapView.removeAnnotations(mapView.annotations)
            let annotations = parent.viewModel.venueAnnotations.map { venue in
                let annotation = MKPointAnnotation()
                annotation.coordinate = venue.coordinate
                annotation.title = venue.title
                return annotation
            }
            mapView.addAnnotations(annotations)
        }
    }
} 