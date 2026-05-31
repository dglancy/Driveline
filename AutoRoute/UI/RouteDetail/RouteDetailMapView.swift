//
//  RouteDetailMapView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct RouteDetailMapView: View {

  // MARK: - Properties

  let route: Route

  // MARK: - Computed Properties

  private var coordinates: [CLLocationCoordinate2D] {
    route.orderedPositions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  private var initialCameraPosition: MapCameraPosition {
    guard coordinates.count > 1 else {
      return coordinates.first.map {
        .region(MKCoordinateRegion(center: $0, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
      } ?? .automatic
    }
    let lats = coordinates.map(\.latitude)
    let lons = coordinates.map(\.longitude)
    guard let minLat = lats.min(), let maxLat = lats.max(),
          let minLon = lons.min(), let maxLon = lons.max() else { return .automatic }
    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
    let latDelta = max((maxLat - minLat) * 1.5, 0.005)
    let lonDelta = max((maxLon - minLon) * 1.5, 0.005)
    return .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)))
  }

  // MARK: - Body

  var body: some View {
    Map(initialPosition: initialCameraPosition) {
      if coordinates.count > 1 {
        MapPolyline(coordinates: coordinates)
          .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
      }

      if let start = coordinates.first {
        Annotation("", coordinate: start, anchor: .center) {
          startMarker
        }
      }

      if let end = coordinates.last, coordinates.count > 1 {
        Annotation("", coordinate: end, anchor: .bottom) {
          Image(systemName: "flag.pattern.checkered.circle.fill")
            .font(.system(size: 28))
            .foregroundStyle(.red, Color(.systemBackground))
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        }
      }
    }
    .mapStyle(.standard(emphasis: .muted))
  }

  // MARK: - Private Views

  private var startMarker: some View {
    Circle()
      .fill(Color.green)
      .frame(width: 14, height: 14)
      .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2.5))
      .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
  }
}
