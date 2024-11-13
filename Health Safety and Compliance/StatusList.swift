//
//  StatusList.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 15/10/2024.
//

import SwiftUI
import MapKit
import CoreLocation

struct StatusList: View {
    @StateObject var signInManager = SignInManager(userId: "user_id", firstName: "First", lastName: "Last") // Update with actual user ID and names
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Custom Map View
                UsersMapView(users: $signInManager.signedInUsers) // Pass as Binding
                    .frame(height: 300)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding(.horizontal)
                
                // List of Signed-in Users
                List(signInManager.signedInUsers) { user in
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 250)
                .cornerRadius(15)
                .shadow(radius: 5)
            }
            .onAppear {
                fetchUsers()
            }
            .navigationBarItems(trailing: Button(action: {
                fetchUsers()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title)
                    .foregroundColor(.blue)
            })
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private func fetchUsers() {
        isLoading = true
        signInManager.fetchSignedInUsers()
        isLoading = false
    }
}

struct UsersMapView: View {
    @Binding var users: [User] // Make users a Binding

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 53.4808, longitude: -2.2426), // Manchester, NW England
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: users.filter { $0.location != nil }) { user in
            MapAnnotation(coordinate: user.location!) {
                VStack {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.caption2)
                        .padding(5)
                        .background(Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }.onAppear {
                    // Adjust the map to center based on the first user's location, if available
                    updateRegion()
                }
                .onChange(of: users) { _ in
                    updateRegion() // Update region whenever users change
                }
            }
        }
        .mapStyle(.hybrid())
    }

    private func updateRegion() {
        // Adjust the map region when the users list changes
        if let firstUserLocation = users.first(where: { $0.location != nil })?.location {
            region.center = firstUserLocation
            region.span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5) // Zoom in on users
        } else {
            // If no users are available, you can set a default region or keep the previous region
            // For example, keep the current region or reset to a default location
        }
    }
}

extension MKMapRect {
    init(_ region: MKCoordinateRegion) {
        let topLeft = MKMapPoint(CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2))

        let bottomRight = MKMapPoint(CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2))

        self = MKMapRect(
            origin: MKMapPoint(
                x: min(topLeft.x, bottomRight.x),
                y: min(topLeft.y, bottomRight.y)),
            size: MKMapSize(
                width: abs(topLeft.x - bottomRight.x),
                height: abs(topLeft.y - bottomRight.y))
        )
    }
}

#Preview {
    StatusList()
}
