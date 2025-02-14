//
//  EditSubcontractorsView.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 12/02/2025.
//


import SwiftUI
import FirebaseFirestore

struct Subcontractor: Identifiable {
    let id: String  // Firestore document ID
    var name: String
    var isActive: Bool
}

struct EditSubcontractorsView: View {
    @State private var subcontractors: [Subcontractor] = []
    @State private var isEditing = false
    @State private var newSubcontractorName = ""
    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            List {
                Section(header: Text("Current Subcontractors")) {
                        ForEach($subcontractors) { $subcontractor in
                            HStack {
                                Text(subcontractor.name)
                                Spacer()
                                
                                Button(action: {
                                    toggleSubcontractorStatus(subcontractor: subcontractor)
                                }) {
                                    Image(systemName: subcontractor.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(subcontractor.isActive ? .green : .red)
                                }
                            }
                        }
                        .onDelete(perform: deleteSubcontractor)
                    }

                if isEditing {
                    Section(header: Text("Add New Subcontractor")) {
                        HStack {
                            TextField("New Subcontractor Name", text: $newSubcontractorName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: addNewSubcontractor) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            .disabled(newSubcontractorName.isEmpty)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
            }
            .padding()
            .background(isEditing ? Color.green : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear(perform: fetchSubcontractors)
    }
    
    // MARK: - Firebase Operations
    private func fetchSubcontractors() {
        db.collection("subcontractors")
            .order(by: "name")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching subcontractors: \(error.localizedDescription)")
                    return
                }
                subcontractors = snapshot?.documents.compactMap { doc in
                    if let name = doc.data()["name"] as? String,
                       let isActive = doc.data()["isActive"] as? Bool {
                        return Subcontractor(id: doc.documentID, name: name, isActive: isActive)
                    }
                    return nil
                } ?? []
            }
    }

    private func updateSubcontractor(subcontractor: Subcontractor, newName: String) {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Name cannot be empty.")
            return
        }
        
        db.collection("subcontractors").document(subcontractor.name).updateData(["name": newName]) { error in
            if let error = error {
                print("Error updating subcontractor: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleSubcontractorStatus(subcontractor: Subcontractor) {
        let newStatus = !subcontractor.isActive

        db.collection("subcontractors").document(subcontractor.id).updateData([
            "isActive": newStatus
        ]) { error in
            if let error = error {
                print("Error updating status: \(error.localizedDescription)")
                return
            }
            
            // Update the local state
            if let index = subcontractors.firstIndex(where: { $0.id == subcontractor.id }) {
                subcontractors[index].isActive = newStatus
            }
        }
    }

    private func addNewSubcontractor() {
        let subcontractorID = generateUniqueID(existingIDs: subcontractors.map { $0.id.hashValue % 9000 + 1000 }) // Ensure uniqueness
        let docRef = db.collection("subcontractors").document() // Auto-generate ID
        
        let newSubcontractorData: [String: Any] = [
            "name": newSubcontractorName,
            "isActive": true,
            "subcontractorID": subcontractorID
        ]
        
        docRef.setData(newSubcontractorData) { error in
            if let error = error {
                print("Error adding subcontractor: \(error.localizedDescription)")
                return
            }
            
            let newSubcontractor = Subcontractor(id: docRef.documentID, name: newSubcontractorName, isActive: true)
            subcontractors.append(newSubcontractor)
            newSubcontractorName = ""
        }
    }

    private func deleteSubcontractor(at offsets: IndexSet) {
        for index in offsets {
            let subcontractorToDelete = subcontractors[index]
            
            db.collection("subcontractors").document(subcontractorToDelete.id).delete { error in
                if let error = error {
                    print("Error deleting subcontractor: \(error.localizedDescription)")
                } else {
                    subcontractors.remove(at: index)
                }
            }
        }
    }
    
    private func updateAllSubcontractors() {
        let db = Firestore.firestore()
        let subcontractorsRef = db.collection("subcontractors")

        subcontractorsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching subcontractors: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            for document in documents {
                let subcontractorID = generateUniqueID(existingIDs: documents.map { $0["subcontractorID"] as? Int ?? 0 })
                let docRef = subcontractorsRef.document(document.documentID)

                docRef.updateData([
                    "isActive": true,
                    "subcontractorID": subcontractorID
                ]) { error in
                    if let error = error {
                        print("Error updating subcontractor \(document.documentID): \(error.localizedDescription)")
                    } else {
                        print("Updated subcontractor \(document.documentID) with ID \(subcontractorID) and isActive: true")
                    }
                }
            }
        }
    }
    
    private func generateUniqueID(existingIDs: [Int]) -> Int {
        var newID: Int
        repeat {
            newID = Int.random(in: 1000...9999) // Generate 4-digit number
        } while existingIDs.contains(newID)  // Ensure uniqueness
        return newID
    }
}

#Preview {
    EditSubcontractorsView()
}
