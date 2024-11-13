//
//  Register Manager.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 07/10/2024.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import MapKit
import CoreLocation

struct User: Identifiable, Equatable {
    var id = UUID()
    var firstName: String
    var lastName: String
    var location: CLLocationCoordinate2D?
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.location?.latitude == rhs.location?.latitude &&
               lhs.location?.longitude == rhs.location?.longitude
    }
}

class SignInManager: ObservableObject {
    @Published var signInRecords: [SignInRecord] = []
    @Published var signedInUsers: [User] = []
    
    @AppStorage("signedIn") var signedIn: Bool = false
    
    private let db = Firestore.firestore()
    private let userId: String
    private let firstName: String
    private let lastName: String
    
    init(userId: String, firstName: String, lastName: String) {
            self.userId = userId
            self.firstName = firstName
            self.lastName = lastName
            
            listenForSignInStatus()
            listenForSignedInUsers()
        }
    
    // Add a new sign-in record
    func addSignInRecord(time: String, location: String, status: String, contractName: String) {
        let newRecord = SignInRecord(
            time: time,
            location: location,
            status: status,
            contract: contractName,
            firstName: firstName,
            lastName: lastName
        )
        
        signInRecords.insert(newRecord, at: 0)
        saveToFirestore(record: newRecord)
    }
    
    func fetchSignedInUsers() {
            db.collection("users").whereField("isSignedIn", isEqualTo: true).getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching signed-in users: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = querySnapshot else {
                    print("No signed-in users found.")
                    return
                }

                DispatchQueue.main.async {
                    // Map the fetched documents to User objects
                    self.signedInUsers = snapshot.documents.compactMap { document in
                        let data = document.data()
                        
                        // Check and extract firstName, lastName, and signInLocation
                        guard let firstName = data["firstName"] as? String,
                              let lastName = data["lastName"] as? String,
                              let signInLocation = data["signInLocation"] as? [String: Any],
                              let latitude = signInLocation["latitude"] as? CLLocationDegrees,
                              let longitude = signInLocation["longitude"] as? CLLocationDegrees else {
                            print("Error parsing user data for document: \(document.documentID)")
                            return nil
                        }
                        
                        // Create CLLocationCoordinate2D object
                        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        
                        // Create and return User object
                        print("Fetched user: \(firstName) \(lastName), location: \(latitude), \(longitude)")
                        return User(firstName: firstName, lastName: lastName, location: location)
                    }
                }
            }
        }
    
    private func listenForSignedInUsers() {
        db.collection("users").whereField("isSignedIn", isEqualTo: true).addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error listening for signed-in users: \(error.localizedDescription)")
                return
            }

            guard let snapshot = querySnapshot else {
                print("Snapshot does not exist")
                return
            }

            DispatchQueue.main.async {
                withAnimation {
                    self.signedInUsers = snapshot.documents.compactMap { document in
                        let data = document.data()
                        if let firstName = data["firstName"] as? String,
                           let lastName = data["lastName"] as? String {
                            return User(firstName: firstName, lastName: lastName)
                        }
                        return nil
                    }
                }
            }
        }
    }
    
    func isCurrentUserSignedIn(completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let document = document, document.exists else {
                completion(false)
                return
            }
            
            if let isSignedIn = document.data()?["isSignedIn"] as? Bool {
                completion(isSignedIn)
            } else {
                completion(false) // Default to false if the field does not exist
            }
        }
    }
    
    private func listenForSignInStatus() {
            db.collection("users").document(userId).addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error listening for sign-in status: \(error.localizedDescription)")
                    return
                }

                guard let document = documentSnapshot else {
                    print("Document does not exist")
                    return
                }

                if let isSignedIn = document.data()?["isSignedIn"] as? Bool {
                    DispatchQueue.main.async {
                        self.signedIn = isSignedIn // Update the published property
                        self.fetchSignedInUsers() // Fetch signed-in users whenever the status changes
                    }
                }
            }
        }
    
    // Save the record to Firestore
    private func saveToFirestore(record: SignInRecord) {
        let recordData: [String: Any] = [
            "time": record.time,
            "location": record.location,
            "status": record.status,
            "contract": record.contract,
            "firstName": record.firstName,
            "lastName": record.lastName,
            "userID": userId
        ]
        
        db.collection("signInRecords").addDocument(data: recordData) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Record successfully written!")
            }
        }
    }
    
    func filterRecordsByDate(selectedDate: Date, isAdmin: Bool) {
        let calendar = Calendar.current
        let selectedDayStart = calendar.startOfDay(for: selectedDate)
        let selectedDayEnd = calendar.date(byAdding: .day, value: 1, to: selectedDayStart)!

        var query: Query = db.collection("signInRecords")
            .whereField("time", isGreaterThanOrEqualTo: formatDate(date: selectedDayStart))
            .whereField("time", isLessThanOrEqualTo: formatDate(date: selectedDayEnd))

        if !isAdmin {
            // For non-admins, restrict records to their own userId
            query = query.whereField("userID", isEqualTo: userId)
        }

        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching documents: \(error)")
            } else if let snapshot = querySnapshot {
                DispatchQueue.main.async {
                    self.signInRecords = snapshot.documents.compactMap { document in
                        let data = document.data()
                        if let timeString = data["time"] as? String,
                           let time = self.parseTime(from: timeString),
                           calendar.isDate(time, inSameDayAs: selectedDate) {
                            return SignInRecord(
                                time: timeString,
                                location: data["location"] as? String ?? "N/A",
                                status: data["status"] as? String ?? "N/A",
                                contract: data["contract"] as? String ?? "N/A",
                                firstName: data["firstName"] as? String ?? "N/A",
                                lastName: data["lastName"] as? String ?? "N/A"
                            )
                        }
                        return nil
                    }
                    // Sort by time in descending order
                    .sorted { self.parseTime(from: $0.time)! > self.parseTime(from: $1.time)! }
                }
            }
        }
    }
    
    
    
    // Fetch sign-in records based on admin view
    func fetchSignInRecords(isAdmin: Bool) {
            let today = Calendar.current.startOfDay(for: Date())
            let query: Query

            if isAdmin {
                // Admin can see all sign-in records
                query = db.collection("signInRecords")
            } else {
                // Non-admin can see only their sign-in records
                query = db.collection("signInRecords").whereField("userID", isEqualTo: userId)
            }

            query.getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                } else if let snapshot = querySnapshot {
                    DispatchQueue.main.async {
                        self.signInRecords = snapshot.documents.compactMap { document in
                            let data = document.data()
                            if let timeString = data["time"] as? String,
                               let time = self.parseTime(from: timeString) {
                                // Filter records for today if not admin
                                if !isAdmin && Calendar.current.startOfDay(for: time) != today {
                                    return nil
                                }
                                return SignInRecord(
                                    time: timeString,
                                    location: data["location"] as? String ?? "N/A",
                                    status: data["status"] as? String ?? "N/A",
                                    contract: data["contract"] as? String ?? "N/A",
                                    firstName: data["firstName"] as? String ?? "N/A",
                                    lastName: data["lastName"] as? String ?? "N/A"
                                )
                            }
                            return nil
                        }
                        .sorted { self.parseTime(from: $0.time)! > self.parseTime(from: $1.time)! }
                    }
                }
            }
        }
    
    private func parseTime(from timeString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: timeString)
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
}

