import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct SignInRecord: Identifiable {
    let id = UUID()  // Swift will generate the id automatically
    let time: String
    let location: String
    let status: String
    let contract: String
    let firstName: String
    let lastName: String
    let signedInBy: String?
}

var contracts: [Contract] = []

func fetchContractsFromFirebase() {
    let db = Firestore.firestore()
    
    if let user = Auth.auth().currentUser {
        print("User is authenticated: \(user.uid)")
    } else {
        print("User is not authenticated")
    }
    
    db.collection("contracts").order(by: "name").getDocuments { (snapshot, error) in
        if let error = error {
            print("Error fetching contracts: \(error.localizedDescription)")
            return
        }
        
        // Parse documents into Contract objects
        if let snapshot = snapshot {
            contracts = snapshot.documents.compactMap { doc in
                guard let name = doc.data()["name"] as? String else {
                    return nil
                }
                return Contract(name: name) // Automatically generates a UUID for `id`
            }
            //print("Contracts fetched: \(contracts)")
        }
    }
}


struct SignIn: View {
    @StateObject private var timeManager = TimeManager()
    @StateObject private var locationManager = LocationManager()

    
    @AppStorage("signedIn") var signedIn: Bool = false
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    @AppStorage("firstName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""
    @AppStorage("uid") var userId: String?
    @AppStorage("isAdmin") var isAdmin: Bool = false
    
    @State private var adminView: Bool = false
    @State private var signInManager: SignInManager?
    @State private var selectedContract: Contract?
    @State private var isCalendarPresented = false
    @State private var selectedDate = Date()
    
    @State private var isManualRegisterShowing: Bool = false
    @State private var guestFirstName: String = ""
    @State private var guestLastName: String = ""
    @State private var guestStatus: String = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var showSignInSheet = false
    @State private var question1Answer = false
    @State private var question2Answer = false
    @State private var question3Answer = false
    @State private var question4Answer = false
    @State private var question5Answer = false
    @State private var question6Answer = false
    @State private var question7Answer = false
    @State private var question8Answer = false
    @State private var question9Answer = false
    
    
    
    
    
    fileprivate func setSignInStatus(isSignedIn: Bool) {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()

            // Create a timestamp for the current date and time
            let lastUpdated = Timestamp(date: Date())
            let contractName = selectedContract?.name ?? "No Contract Selected"

            if let location = locationManager.userLocation {
                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                let signInLocation: [String: Any] = [
                    "latitude": latitude,
                    "longitude": longitude
                ]
                let signInAddress = locationManager.userAddress ?? "none"

                // Update both 'isSignedIn' and 'lastUpdated' fields
                var updateData: [String: Any] = [
                    "isSignedIn": isSignedIn,
                    "lastUpdated": lastUpdated,
                    "contract": isSignedIn ? contractName : "None",
                    "signInLocation": isSignedIn ? signInLocation : "None",
                    "signInAddress": isSignedIn ? signInAddress : "None"
                ]

                db.collection("users").document(userId).updateData(updateData) { error in
                    if let error = error {
                        // Show error alert
                        alertMessage = "Error updating sign-in status: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        print("User's sign-in status updated to \(isSignedIn ? "true" : "false") at \(lastUpdated).")
                    }
                }
            } else {
                alertMessage = "User location is unavailable."
                showAlert = true
            }
        }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Menu {
                        ForEach(contracts) { contract in
                            Button(action: {
                                selectedContract = contract
                            }) {
                                Text(contract.name)
                            }
                        }
                    } label: {
                        Text(selectedContract?.name ?? "Contract")
                        Image(systemName: "chevron.down")
                    }
                    //.disabled(signedIn)
                    Spacer()
                    Button {
                        isCalendarPresented.toggle() // Toggle calendar
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.green)
                    }
                    .sheet(isPresented: $isCalendarPresented) {
                        VStack {
                            DatePicker(
                                "Select Date",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(GraphicalDatePickerStyle()) // Use a graphical calendar
                            .padding()
                            
                            Button("Done") {
                                isCalendarPresented = false
                                signInManager?.filterRecordsByDate(selectedDate: selectedDate, isAdmin: isAdmin)
                            }
                            .padding()
                        }
                    }
                    if isAdmin {
                        Spacer()
                        Button {
                            adminView.toggle()
                            signInManager?.fetchSignInRecords(isAdmin: adminView) // Fetch records based on admin view status
                        } label: {
                            Image(systemName: adminView ? "eye" : "eye.slash")
                                .foregroundStyle(.blue)
                        }
                        NavigationLink(destination: StatusList()) {
                            Image(systemName: "list.bullet")
                                .foregroundStyle(.blue) // Adjust size if necessary
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }.padding(.horizontal)
                
                
                if selectedContract != nil {
                    Button(action: {
                        if !signedIn {
                            // Show the sheet for signing in
                            showSignInSheet.toggle()
                        } else {
                            // Directly sign out without the sheet
                            withAnimation(.easeInOut(duration: 0.3)) {
                                signedIn.toggle()
                            }
                            let time = signInManager?.formatDate(date: Date()) ?? ""
                            let location = locationManager.userAddress ?? "Location unavailable"
                            let status = signedIn ? "Signing In" : "Signing Out"
                            let contractName = selectedContract?.name ?? "No Contract Selected"
                            
                            signInManager?.addSignInRecord(time: time, location: location, status: status, contractName: contractName)
                            setSignInStatus(isSignedIn: false)
                        }
                    }) {
                        HStack {
                            Image(systemName: signedIn ? "person.fill.checkmark" : "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .scaleEffect(signedIn ? 1.2 : 1.0)  // Scale effect for the icon
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: signedIn)
                            
                            Text(signedIn ? "Sign Out" : "Sign In")
                                .font(Font.custom("Poppins-Medium", size: 18))
                                .foregroundColor(.white)
                                .padding(.leading, 5)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(gradient: Gradient(colors: signedIn ? [.red, .orange] : [.green, .blue]),
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                                )
                        )
                        .shadow(color: signedIn ? Color.red.opacity(0.5) : Color.green.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .scaleEffect(signedIn ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: signedIn)
                        
                        
                    }
                    .disabled(!isAuthenticated)
                    
                    .sheet(isPresented: $showSignInSheet) {
                        VStack {
                            Text("Point of works Risk Assessment")
                                .font(.headline)
                                .padding()
                            
                            Toggle("I have got the correct information to do the job", isOn: $question1Answer)
                                .padding(.bottom, 10)
                            Toggle("I have read and understood the relevant safe systems of work", isOn: $question2Answer)
                                .padding(.bottom, 10)
                            Toggle("I understand what measures I must do to control the hazards / risks", isOn: $question3Answer)
                                .padding(.bottom, 10)
                            Toggle("I have the correct PPE for the task", isOn: $question4Answer)
                                .padding(.bottom, 10)
                            Toggle("I have the correct equipment", isOn: $question5Answer)
                                .padding(.bottom, 10)
                            Toggle("I have been trained to do the task and operate the equipment provided", isOn: $question6Answer)
                                .padding(.bottom, 10)
                            Toggle("I know and understand what actions to take in the event of an emergency", isOn: $question7Answer)
                                .padding(.bottom, 10)
                            Toggle("I have evidence of my identification/qualifications to hand", isOn: $question8Answer)
                                .padding(.bottom, 10)
                            Toggle("I have assessed the point of works for risk", isOn: $question9Answer)
                                .padding(.bottom, 10)
                            
                            Button(action: {
                                if question1Answer && question2Answer && question3Answer && question4Answer && question5Answer && question6Answer && question7Answer && question8Answer {
                                    // All questions are answered, proceed with sign-in
//                                    showSignInSheet = false
//                                    question1Answer = false
//                                    question2Answer = false
//                                    question3Answer = false
//                                    question4Answer = false
//                                    question5Answer = false
//                                    question6Answer = false
//                                    question7Answer = false
//                                    question8Answer = false
                                    
                                    let time = signInManager?.formatDate(date: Date()) ?? ""
                                    let location = locationManager.userAddress ?? "Location unavailable"
                                    let status = "Signing In"
                                    let contractName = selectedContract?.name ?? "No Contract Selected"
                                    
                                    signInManager?.addSignInRecord(time: time, location: location, status: status, contractName: contractName)
                                    signedIn = true
                                    
                                    setSignInStatus(isSignedIn: true)
                                    
                                    // Dismiss the sheet
                                    showSignInSheet = false
                                } else {
                                    // Dismiss the sheet first, then show the alert
                                    showSignInSheet = false
                                    
                                    // Delay showing the alert to allow the sheet to dismiss first
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        alertMessage = "Please ensure all questions are answered before proceeding."
                                        showAlert = true
                                    }
                                }
                            }) {
                                Text("Done")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(20)
                    }
                    Button {
                        isManualRegisterShowing = true
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Anyone without a device?")
                        }
                        .foregroundStyle(.green)
                    }
                    
                    .sheet(isPresented: $isManualRegisterShowing) {
                        let time = signInManager?.formatDate(date: Date()) ?? ""
                        let location = locationManager.userAddress ?? "Location unavailable"
                        let contractName = selectedContract?.name ?? "No Contract Selected"

                        VStack(spacing: 20) {
                            // Header
                            Text("Welcome, Guest")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // Tooltip / Hint
                            Text("""
                            You should only use this feature when:
                            • A co-worker doesn't have access to a smartphone/tablet.
                            • A visitor or guest is on site and needs to register their presence.
                            • A co-workers device is malfunctioning or cannot connect to the system.
                            """)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                        .shadow(color: Color(.black).opacity(0.1), radius: 3, x: 0, y: 2)
                                )
                                .padding(.horizontal)

                            // Guest Status Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Status")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Picker("", selection: $guestStatus) {
                                    Text("Sign In").tag("Signing In")
                                    Text("Sign Out").tag("Signing Out")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding(.horizontal)

                            // Name Input Fields
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Guest Name")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 12) {
                                    TextField("Forename", text: $guestFirstName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    TextField("Surname", text: $guestLastName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .padding(.horizontal)
                            
                            Spacer()

                            // Done Button
                            Button(action: {
                                signInManager?.addSignInRecordManually(
                                    firstName1: guestFirstName,
                                    lastName1: guestLastName,
                                    time: time,
                                    location: location,
                                    status: guestStatus,
                                    contractName: contractName,
                                    signedInBy: "\(firstName) \(lastName)"
                                )
                                guestFirstName = ""
                                guestLastName = ""
                                isManualRegisterShowing = false
                            }) {
                                Text("Done")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)

                        }
                        .frame(width: 320)
                        .padding(.top)
                    }
                    
                } else {
                    Text("Select a contract to sign in")
                        .italic()
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                
                Divider()
                
                // Display the sign-in records based on admin view status
                List(signInManager?.signInRecords ?? []) { record in
                    VStack(alignment: .leading) {
                        Text("\(record.firstName) \(record.lastName)")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Contract: \(record.contract)")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                        Text("Status: \(record.status)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Text("Location: \(record.location)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Time: \(record.time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Warning"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // Initialize the signInManager when the view appears
                fetchContractsFromFirebase()
                signInManager = SignInManager(userId: userId ?? "0", firstName: firstName, lastName: lastName)
                signInManager?.fetchSignInRecords(isAdmin: adminView) // Fetch records on appear
            }
        }
        
    }
}

#Preview {
    SignIn()
}
