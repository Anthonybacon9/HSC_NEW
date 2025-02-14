//
//  EditContractsView.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 10/12/2024.
//

import SwiftUI
import FirebaseFirestore

struct Contract: Identifiable {
    let id = UUID()
    var name: String
}

struct EditContractsView: View {
    @State private var contracts: [Contract] = []
    @State private var isEditing = false
    @State private var newContractName = ""
    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            List {
                Section(header: Text("Current Contracts")) {
                    ForEach($contracts) { $contract in
                        if isEditing {
                            HStack {
                                TextField("Contract Name", text: $contract.name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: contract.name) { newName in
                                        updateContract(contract: contract, newName: newName)
                                    }
                            }
                        } else {
                            Text(contract.name)
                        }
                    }
                    .onDelete(perform: deleteContract)
                }

                if isEditing {
                    Section(header: Text("Add New Contract")) {
                        HStack {
                            TextField("New Contract Name", text: $newContractName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: addNewContract) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            .disabled(newContractName.isEmpty)
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
        .onAppear(perform: fetchContracts)
    }
    
    // MARK: - Firebase Operations
    private func fetchContracts() {
        db.collection("contracts")
            .order(by: "name")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching contracts: \(error.localizedDescription)")
                    return
                }
                contracts = snapshot?.documents.compactMap { doc in
                    if let name = doc.data()["name"] as? String {
                        return Contract(name: name) // Generate a UUID for local use
                    }
                    return nil
                } ?? []
            }
    }

    private func updateContract(contract: Contract, newName: String) {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Name cannot be empty.")
            return
        }
        
        db.collection("contracts").document(contract.name).updateData(["name": newName]) { error in
            if let error = error {
                print("Error updating contract: \(error.localizedDescription)")
            }
        }
    }

    private func addNewContract() {
        let newContract = Contract(name: newContractName)
        db.collection("contracts").document(newContract.name).setData(["name": newContractName]) { error in
            if let error = error {
                print("Error adding contract: \(error.localizedDescription)")
                return
            }
            contracts.append(newContract)
            newContractName = ""
        }
    }

    private func deleteContract(at offsets: IndexSet) {
        for index in offsets {
            let contractToDelete = contracts[index]
            db.collection("contracts").document(contractToDelete.name).delete { error in
                if let error = error {
                    print("Error deleting contract: \(error.localizedDescription)")
                } else {
                    contracts.remove(at: index)
                }
            }
        }
    }
    
}

#Preview {
    EditContractsView()
}
