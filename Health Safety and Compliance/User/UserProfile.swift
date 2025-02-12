import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UniformTypeIdentifiers
import PhotosUI
import PDFKit

struct Address: Identifiable {
    var id: String
    var firstLine: String
    var postcode: String
    var asbestosSafe: Bool
}

struct UserProfile: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    @AppStorage("firstName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""
    @AppStorage("uid") var userId: String?
    @AppStorage("isAdmin") var isAdmin: Bool = false
    @AppStorage("subcontractor") var subcontractor: String = ""
    @AppStorage("job") var job: String = ""

    
    
    @State private var selectedTab: String = "Safety Passport"
    private var tabs: [String] {
        var baseTabs = ["Safety Passport", "Site Check", "Account"]
        if isAdmin {
            baseTabs.insert("Admin", at: 2) // Add "Admin" at the desired index
        }
        return baseTabs
    }
    
    @State private var phoneNumber = ""
    @State private var countryCode: String = "+44"
    @State private var isAuthPresented = true
    @State private var isPhoneAuthSelected = false
    @State private var verificationCode: String = ""
    @State private var MFAEnabled: Bool = false
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var inviteCode = ""
    @State private var generatedInviteCode = ""
    @State private var isCreatingAccount = false
    @State private var isShowingPasswordChange = false
    @State private var isShowingInviteCodeError = false
    @State private var isSubcontractor = false
    @State private var subcontractors: [String] = []
    @State private var jobRoles: [String] = []
    @State private var selectedJobRole = "None"
    @State private var selectedSubcontractor = "Next Energy"
    @State private var errorMessage: String? = nil
    
    @State private var cardShowing: Bool = false
    
    @State private var faceFitImages: [IdentifiableImage] = []
    @State private var faceFitPDFs: [URL] = []
    
    @State private var asbestosImages: [IdentifiableImage] = []
    @State private var asbestosPDFs: [URL] = []
    
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPDF: URL? = nil
    @State private var showImagePicker = false
    @State private var showPDFPicker = false
    @State private var selectedImageForViewing: IdentifiableImage?
    @State private var isImageViewerPresented = false
    @State private var selectedExpiryDate: Date = Date()
    
    
    var body: some View {
        ZStack {
            
            VStack {
                if isAuthenticated {
                    ScrollView {
                        VStack(spacing: 15) {
                            profileHeader
                            
                            // Custom Tab Selection with SF Symbols
                            customTabPicker
                            
                            // Tab Content
                            if selectedTab == "Safety Passport" {
                                safetyPassportSection
                            } else if selectedTab == "Account" {
                                accountManagementSection
                            } else if selectedTab == "Site Check" {
                                SiteCheckView()
                            } else if selectedTab == "Admin" && isAdmin {
                                NavigationView {
                                    adminSection
                                }
                                .frame(minHeight:700)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .cornerRadius(20)
                    }
                } else {
                    if isCreatingAccount {
                        signUpForm
                    } else {
                        signInForm
                    }
                }
            }
            .onAppear(perform: setup)
//            .onAppear(perform:resetAppStorage)
            
            if cardShowing {
                Color.black
                    .opacity(0.3) // Static opacity for dimming
                    .ignoresSafeArea()
                    .onTapGesture {
                        cardShowing = false // Ensure `cardShowing` is set to false
//                        withAnimation(.spring()) {
//                            isShowingQualificationsSheet = false
//                            isShowingFaceFitSheet = false
//                            isAsbestosShowing = false
//                        }
                        isShowingQualificationsSheet = false
                        isShowingFaceFitSheet = false
                        isAsbestosShowing = false
                        isInductionShowing = false
                    }
                    .transition(.opacity) // Only fade in/out
            }

            if isShowingQualificationsSheet {
                QualificationsSheet() // Smooth scaling for the card only
            }
            
            if isShowingFaceFitSheet {
                FaceFitSheet()
            }
            
            if isAsbestosShowing {
                AsbestosSheet()
            }
            
            if isInductionShowing {
                InductionSheet()
            }
        }
                            
    }
    private var customTabPicker: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack {
                        // SF Symbol selection based on tab name
                        Image(systemName: tab == "Safety Passport" ? "shield" :
                               tab == "Account" ? "gear" :
                               tab == "Asbestos Survey" ? "doc.text.magnifyingglass" :
                               tab == "Admin" ? "person.crop.circle.badge.checkmark" : "house.lodge")
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? .green : .gray)
                            .padding(.bottom, 5)
                        
                        // Optional label for the tab
                        Text(tab == "Safety Passport" ? "Passport" :
                             tab == "Account" ? "Account" :
                             tab == "Asbestos Survey" ? "Projects" :
                             tab == "Admin" ? "Admin" : "Projects")
                            .font(.caption)
                            .foregroundColor(selectedTab == tab ? .green : .gray)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == tab ? Color.green.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab) // Smooth transition
                }
            }
        }
        .padding(.top, 10)
    }
    
    let columns: [GridItem] = [
        GridItem(.flexible()), // Flexible width
        GridItem(.flexible())  // Flexible width
    ]
    
    
    
    
    // MARK: - Safety Passport Section
    
    @State private var isShowingQualificationsSheet = false
    @State private var isShowingFaceFitSheet = false
    @State private var isAsbestosShowing = false
    @State private var isInductionShowing = false
    @State private var animateSheet = false
    
    private var safetyPassportSection: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            
            Button(action: {
                cardShowing.toggle()
                withAnimation(.spring()) {
                    isAsbestosShowing.toggle()
                }
            }) {
                Rectangle()
                    .fill(Color.orange)
                    .opacity(0.3)
                    .background(.thinMaterial)
                    .frame(height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle") // SF Symbol for Asbestos Awareness
                                .font(.system(size: 50))
                            Text("Asbestos Awareness")
                                .font(.title3)
                                .multilineTextAlignment(.center) // Center-align the text horizontally
                                .frame(maxWidth: .infinity) // Make sure the text uses available space
                        }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills the Rectangle's frame
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                cardShowing.toggle()
                withAnimation(.spring()) {
                    isShowingFaceFitSheet.toggle()
                }
            }) {
                Rectangle()
                    .fill(Color.purple)
                    .opacity(0.3)
                    .background(.thinMaterial)
                    .frame(height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "face.dashed") // SF Symbol for Facefit Cert
                                .font(.system(size: 50))
                            Text("Facefit")
                                .font(.title3)
                                .multilineTextAlignment(.center) // Center-align the text horizontally
                                .frame(maxWidth: .infinity) // Make sure the text uses available space
                        }
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills the Rectangle's frame
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                cardShowing.toggle()
                withAnimation(.spring()) {
                    isInductionShowing.toggle()
                }
            }) {
                Rectangle()
                    .fill(Color.red)
                    .opacity(0.3)
                    .background(.thinMaterial)
                    .frame(height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "checkmark.seal") // SF Symbol for Induction Confirmation
                                .font(.system(size: 50))
                            Text("Induction Confirmation")
                                .font(.title3)
                                .multilineTextAlignment(.center) // Center-align the text horizontally
                                .frame(maxWidth: .infinity) // Make sure the text uses available space
                        }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills the Rectangle's frame
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                cardShowing.toggle()
                withAnimation(.spring()) {
                    isShowingQualificationsSheet.toggle()
                }
            }) {
                Rectangle()
                    .fill(Color.blue)
                    .opacity(0.3)
                    .frame(height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 50))
                            Text("Qualifications")
                                .font(.title3)
                                .multilineTextAlignment(.center)
                        }
                            .foregroundColor(.blue)
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            
        }
    }
    // MARK: - Account Management and Admin Tools
    private var accountManagementAndAdminTools: some View {
        ScrollView {
            VStack(spacing: 25) {
                accountManagementSection
                
                if isAdmin {
                    adminSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - Site Check
//    private var siteCheck: some View {
//        ScrollView {
//            VStack {
//                Text("hello")
//            }
//        }
//    }
    
    struct SiteCheckView: View {
        @StateObject private var viewModel = AddressViewModel()
        
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar to filter addresses
                    TextField("Search addresses", text: $viewModel.searchQuery)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Display addresses using VStack
                    ForEach(viewModel.filteredAddresses, id: \.id) { address in
                        VStack(alignment: .leading, spacing: 10) {
                            // Address details
                            Text(address.firstLine)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(address.postcode)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(address.asbestosSafe ? "Report Attached" : "No Report Attached")
                                .font(.footnote)
                                .foregroundColor(address.asbestosSafe ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Divider between addresses
                            Divider()
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            showAddressDetails(address)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchAddresses()
            }
        }
        
        private func showAddressDetails(_ address: Address) {
            // Handle displaying address details (e.g., navigate to a detail view)
            print("Selected Address: \(address.firstLine), \(address.postcode)")
            // You can push a new view here or present a sheet with address details
        }
    }
    
    struct AddressDetailView: View {
        var address: Address
        
        var body: some View {
            VStack {
                Text(address.firstLine)
                    .font(.largeTitle)
                Text(address.postcode)
                    .font(.title)
                Text(address.asbestosSafe ? "Asbestos Safe" : "Not Asbestos Safe")
                    .font(.body)
                    .foregroundColor(address.asbestosSafe ? .green : .red)
                
                // More details can be added here as needed
            }
            .padding()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(isAdmin ? "Administrator" : "User")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(subcontractor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(job)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
//        .popover(isPresented: $isAuthPresented) {
//            // Your popover content goes here
//            VStack {
//                Text("Enter Phone Number")
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .padding(.bottom, 10)
//                HStack {
//                    Text("🇬🇧+44")
//                        .font(.body)
//                        .fontWeight(.semibold)
//                        .foregroundColor(generatedInviteCode.isEmpty ? .secondary : .primary)
//                        .lineLimit(1)
//                    
//                    TextField("Phone Number", text: $phoneNumber)
//                        .keyboardType(.phonePad)
//                    
//                    if !generatedInviteCode.isEmpty {
//                        Button(action: { UIPasteboard.general.string = generatedInviteCode }) {
//                            Image(systemName: "doc.on.doc")
//                                .foregroundColor(.blue)
//                                .padding(8)
//                                .background(Circle().fill(Color.white).shadow(radius: 3))
//                        }
//                    }
//                    
//                    Spacer()
//                    
//                    Button(action: {
//                        sendVerificationCode()
//                        print(phoneNumber)
//                    }) {
//                        Text("Send Code")
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 10)
//                            .background(Color.green)
//                            .cornerRadius(10)
//                            .shadow(radius: 5)
//                    }
//                }
//                .frame(width: 325)
//                .padding()
//                .background(Color(UIColor.systemGray6))
//                .cornerRadius(15)
//            }
//        }
    }
    
    // MARK: - Account Management Section
    private var accountManagementSection: some View {
        LazyVGrid(columns: columns, spacing: 10) {  // Assuming 'columns' is defined elsewhere
            // Change Password Button
            Button(action: { isShowingPasswordChange = true }) {
                Rectangle()
                    .fill(Color.green)
                    .opacity(0.3)
                    .background(.thinMaterial)
                    .frame(height: 150)
                    .overlay(
                        VStack(spacing: 10) {  // Added spacing for better layout
                            Image(systemName: "key.fill")
                                .font(.system(size: 40))  // Smaller icon size
                            Text("Change Password")
                                .font(.title3)  // Adjusted text size
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)  // Added horizontal padding for better alignment
                        }
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $isShowingPasswordChange) {
                VStack(spacing: 20) {
                    SecureField("New Password", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let error = errorMessage {
                        Text(error).foregroundColor(.red)
                    }
                    
                    Button(action: updatePassword) {
                        Text("Update Password")
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
            
            //MARK: MFA BUTTON
            Button(action: setupMFA) {
                Rectangle()
                    .fill(Color.orange)
                    .opacity(0.3)
                    .background(.thinMaterial)
                    .frame(height: 150)
                    .overlay(
                        VStack(spacing: 10) {  // Added spacing for better layout
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 40))  // Smaller icon size
                            Text("Multi-Factor Authentication")
                                .font(.title3)  // Adjusted text size
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)  // Added horizontal padding for better alignment
                        }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            //MARK: Sign Out Button
            Button(action: signOut) {
                Rectangle()
                    .fill(Color.red)
                    .opacity(0.3)
                    .background(.thinMaterial)
                    .frame(height: 150)
                    .overlay(
                        VStack(spacing: 10) {  // Added spacing for better layout
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .font(.system(size: 40))  // Smaller icon size
                            Text("Sign Out")
                                .font(.title3)  // Adjusted text size
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)  // Added horizontal padding for better alignment
                        }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            
        }
    }
    
    
    
    // MARK: - Admin Section
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            LazyVGrid(columns: columns, spacing: 10) {
                NavigationLink(destination: EditContractsView()) {
                    Rectangle()
                        .fill(Color.green)
                        .opacity(0.3)
                        .frame(height: 150)
                        .overlay(
                            VStack {
                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    .font(.system(size: 50))
                                Text("Edit Contracts")
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                            }
                                .foregroundColor(.green)
                        )
                        .cornerRadius(10)
                }
            }
            
            HStack {
                Text(generatedInviteCode.isEmpty ? "Generate team code" : generatedInviteCode)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(generatedInviteCode.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                
                if !generatedInviteCode.isEmpty {
                    Button(action: { UIPasteboard.general.string = generatedInviteCode }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Circle().fill(Color.white).shadow(radius: 3))
                    }
                }
                
                Spacer()
                
                Button(action: generateInviteCode) {
                    Text("Generate")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(15)
            
            
//            EditContractsView()
        }
        .frame(minHeight: .infinity)
    }
    
    
    private func isPasswordValid(_ password: String) -> Bool {
        // Regular expression for a password with:
        // - At least 12 characters
        // - At least one uppercase letter
        // - At least one number
        // - At least one symbol
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$&*])(?=.*[a-z]).{12,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    
    private func setup() {
        if let user = Auth.auth().currentUser {
            username = user.displayName ?? user.email ?? "Unknown User"
            userId = user.uid
            isAuthenticated = true
        } else {
            resetAppStorage()
        }
    }
    
    private func fetchSubcontractors() {
        Firestore.firestore().collection("subcontractors").order(by: "name").getDocuments { snapshot, _ in
            subcontractors = snapshot?.documents.compactMap { $0["name"] as? String } ?? []
        }
    }
    
    private func fetchJobRoles() {
        Firestore.firestore().collection("JobRoles").order(by: "name").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching job roles: \(error.localizedDescription)")
                return
            }
            
            jobRoles = snapshot?.documents.compactMap { $0["name"] as? String } ?? []
            
            // Ensure a default value is set
            if let firstRole = jobRoles.first {
                selectedJobRole = firstRole
            }
        }
    }
    
    private func resetAppStorage() {
        username = ""; isAuthenticated = false; firstName = ""; lastName = ""; userId = "1"; isAdmin = false
    }
    
    private func generateInviteCode() {
        let code = UUID().uuidString.prefix(8)
        Firestore.firestore().collection("inviteCodes").document(String(code)).setData(["code": code, "isUsed": false]) { _ in
            generatedInviteCode = String(code)
        }
    }
    
    private func validateInviteCodeAndCreateAccount() {
        Firestore.firestore().collection("inviteCodes").document(inviteCode).getDocument { document, _ in
            if let document = document, document.exists, !(document["isUsed"] as? Bool ?? true) {
                createAccount()
            } else {
                isShowingInviteCodeError = true
            }
        }
    }
    
    private func updatePassword() {
        guard newPassword == confirmNewPassword else {
            errorMessage = "New passwords do not match."
            return
        }
        
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                errorMessage = "Failed to update password: \(error.localizedDescription)"
            } else {
                isShowingPasswordChange = false
                print("Password successfully updated!")
            }
        }
    }
    
    private var signInForm: some View {
        VStack(spacing: 20) {
            Text("Sign In").font(.title).fontWeight(.bold)
            TextField("Email", text: $email).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
            SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
            if let error = errorMessage { Text(error).foregroundColor(.red) }
            Button(action: signIn) { Text("Sign In").padding().background(Color.green).foregroundColor(.white).cornerRadius(8) }
            
            Button(action: { isCreatingAccount = true }) { Text("Don't have an account? Create one").foregroundColor(.blue) }
            
            Button("Sign in with Phone Number") {
                        isPhoneAuthSelected = true
                    }
                    .foregroundColor(.blue)
        }.padding()
    }
    
    private var signUpForm: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    // Invite Code
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("Invite Code", text: $inviteCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if isShowingInviteCodeError {
                            Text("Invalid or expired invite code.")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    // First Name and Last Name on the same line
                    HStack {
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        
                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Email
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    // Password and Confirm Password
                    VStack(alignment: .leading, spacing: 5) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // Validation messages
                        if !isPasswordValid(password) {
                            Text("Password must be at least 12 characters long, include at least one uppercase letter, one number, and one symbol.")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        
                        if password != confirmPassword && !confirmPassword.isEmpty {
                            Text("Passwords do not match")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    // Job Role Picker
                    Picker("Select Job Role", selection: $selectedJobRole) {
                        ForEach(jobRoles, id: \.self) { role in
                            Text(role)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Subcontractor Toggle and Picker
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle("Are you a subcontractor?", isOn: $isSubcontractor)
                            .padding(.vertical, 5)
                        
                        if isSubcontractor {
                            Picker("Select Subcontractor", selection: $selectedSubcontractor) {
                                ForEach(subcontractors, id: \.self) { Text($0) }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("Next Energy Employee")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    // Error Message
                    if let error = errorMessage, !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    // Create Account Button
                    Button(action: {
                        createAccount()
                        isAuthPresented = true
                    }) {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPasswordValid(password) && password == confirmPassword ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                    .disabled(!isPasswordValid(password) || password != confirmPassword)
                    
                    // Sign In Button
                    Button(action: { isCreatingAccount = false }) {
                        Text("Already have an account? Sign In")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .onAppear(perform: fetchSubcontractors)
                .onAppear(perform: fetchJobRoles)
            }
        }
        
    private func createAccount() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        Task {
            do {
                let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
                let user = authResult.user
                let fullName = "\(firstName) \(lastName)"

                // Store user data in Firestore
                try await Firestore.firestore().collection("users").document(user.uid).setData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "isAdmin": isAdmin,
                    "employer": selectedSubcontractor,
                    "jobRole": selectedJobRole,
                    "inviteCode": inviteCode,
                    "uid": user.uid,
                    "phoneNumber": phoneNumber,
                    "MFAEnabled": false
                ])

                // Update display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                try await changeRequest.commitChanges()

                // ✅ Send email verification
                try await user.sendEmailVerification()

                DispatchQueue.main.async {
                    isAuthenticated = true
                    username = fullName
                    errorMessage = "Please verify your email before setting up MFA."
                }

            } catch {
                print("Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }

    private func setupMFA() {
        Task {
            guard let user = Auth.auth().currentUser else { return }

            // ✅ Refresh user data
            try await user.reload()

            if !user.isEmailVerified {
                do {
                    try await user.sendEmailVerification()
                    showAlert(title: "Email Verification", message: "A verification email has been sent. Please check your inbox and verify your email before setting up MFA.")
                } catch {
                    showAlert(title: "Error", message: "Failed to send verification email: \(error.localizedDescription)")
                }
                return
            }

            // ✅ Ask the user for their password (since Firebase does not store it)
            let passwordPrompt = await promptForPassword()
            guard let password = passwordPrompt else {
                errorMessage = "You must enter your password to proceed."
                return
            }

            do {
                // ✅ Re-authenticate using the re-entered password
                let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: password)
                try await user.reauthenticate(with: credential)

                // ✅ Generate a TOTP MFA session
                let mfaSession = try await user.multiFactor.session()
                let totpSecret = try await TOTPMultiFactorGenerator.generateSecret(with: mfaSession)

                // ✅ Generate QR Code URL for the authenticator app
                var otpAuthUriString = totpSecret.generateQRCodeURL(
                    withAccountName: user.email ?? "default account",
                    issuer: "HSC"
                )

                // ✅ Properly decode and clean up the URL
                if let decodedUri = otpAuthUriString.removingPercentEncoding {
                    otpAuthUriString = decodedUri
                }

                // ✅ Fix algorithm encoding issue (ensure SHA1 is correctly formatted)
                otpAuthUriString = otpAuthUriString.replacingOccurrences(of: "%25SHA1", with: "SHA1")
                otpAuthUriString = otpAuthUriString.replacingOccurrences(of: "%SHA1", with: "SHA1")
                
                print(otpAuthUriString)

                // ✅ Re-encode properly for URL use
                if let fixedEncodedUri = otpAuthUriString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    otpAuthUriString = fixedEncodedUri
                }

                if let otpAuthUrl = URL(string: otpAuthUriString) {
                    await showMFASetupOptions(otpAuthUri: otpAuthUrl.absoluteString)
                } else {
                    print("❌ Error: Invalid OTP Auth URI")
                }

                // ✅ Wait for user to enter the TOTP code
                let verificationCode = await promptForTOTPCode()
                guard !verificationCode.isEmpty else {
                    errorMessage = "You must enter a valid verification code."
                    return
                }

                // ✅ Finalize MFA Enrollment
                let multiFactorAssertion = TOTPMultiFactorGenerator.assertionForEnrollment(
                    with: totpSecret,
                    oneTimePassword: verificationCode
                )
                try await user.multiFactor.enroll(with: multiFactorAssertion, displayName: "TOTP")

                print("✅ MFA Enrollment Successful!")
                
                try await Firestore.firestore().collection("users").document(user.uid).updateData([
                    "MFAEnabled": true
                ])

            } catch {
                print("❌ Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func showMFASetupOptions(otpAuthUri: String) async {
        guard let url = URL(string: otpAuthUri) else {
            print("❌ Invalid OTP Auth URL")
            return
        }

        // ✅ Extract just the secret from the OTP URI
        let secret: String? = {
            let components = otpAuthUri.components(separatedBy: "secret=")
            if components.count > 1 {
                return components[1].components(separatedBy: "&").first
            }
            return nil
        }()

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Setup MFA",
                    message: "Scan this QR code in your authenticator app or manually enter the setup link.",
                    preferredStyle: .actionSheet
                )

                // ✅ Open Authenticator App
                alert.addAction(UIAlertAction(title: "Open Authenticator App", style: .default, handler: { _ in
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    continuation.resume()
                }))

                // ✅ Copy only the secret to Clipboard
                alert.addAction(UIAlertAction(title: "Copy Secret", style: .default, handler: { _ in
                    if let secret = secret {
                        UIPasteboard.general.string = secret
                        print("✅ Copied Secret: \(secret)")
                    } else {
                        print("❌ Error: Unable to extract secret")
                    }
                    continuation.resume()
                }))

                // ✅ Cancel
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    continuation.resume()
                }))

                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    func promptForPassword() async -> String? {
        // Replace this with a SwiftUI TextField alert or modal
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Re-authentication Required", message: "Enter your password to continue.", preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.isSecureTextEntry = true
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    continuation.resume(returning: nil)
                }))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    let password = alert.textFields?.first?.text
                    continuation.resume(returning: password)
                }))
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func promptForTOTPCode() async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Enter Verification Code",
                                              message: "Enter the TOTP code from your authenticator app.",
                                              preferredStyle: .alert)

                alert.addTextField { textField in
                    textField.placeholder = "6-digit code"
                    textField.keyboardType = .numberPad
                }

                alert.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
                    if let code = alert.textFields?.first?.text {
                        continuation.resume(returning: code)
                    }
                })

                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    continuation.resume(returning: "")
                })

                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            username = ""
            email = ""
            password = ""
            confirmPassword = ""
            firstName = ""
            lastName = ""
            userId = "1"
            phoneNumber = ""
            isAdmin = false
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    private func signIn() {
        Task {
            do {
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                
                // ✅ Successful sign-in (No MFA required)
                handleSuccessfulSignIn(authResult: authResult)
                
            } catch let error as NSError {
                if error.code == AuthErrorCode.secondFactorRequired.rawValue {
                    // ✅ MFA is required, prompt the user for their TOTP code
                    await handleMFA(error: error)
                } else {
                    // Other authentication error
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleMFA(error: NSError) async {
        let mfaKey = AuthErrorUserInfoMultiFactorResolverKey
        guard let resolver = error.userInfo[mfaKey] as? MultiFactorResolver else { return }
        
        let enrolledFactors = resolver.hints.map(\.displayName)
        
        // ✅ Assume the user selects the first enrolled factor (adjust for UI selection)
        guard let multiFactorInfo = resolver.hints.first else {
            errorMessage = "No enrolled MFA factors found."
            return
        }
        
        if multiFactorInfo.factorID == TOTPMultiFactorID {
            // ✅ Prompt user to enter TOTP code
            let otpCode = await promptForTOTPCode()
            
            if otpCode.isEmpty {
                errorMessage = "You must enter a valid TOTP code."
                return
            }
            
            let assertion = TOTPMultiFactorGenerator.assertionForSignIn(
                withEnrollmentID: multiFactorInfo.uid,
                oneTimePassword: otpCode
            )
            
            do {
                // ✅ Complete MFA sign-in
                let authResult = try await resolver.resolveSignIn(with: assertion)
                handleSuccessfulSignIn(authResult: authResult)
            } catch {
                errorMessage = "Invalid or expired OTP. Please try again."
            }
        }
    }
    
    private func handleSuccessfulSignIn(authResult: AuthDataResult) {
        let user = authResult.user
        username = user.displayName ?? user.email ?? "Unknown User"
        userId = user.uid
        isAuthenticated = true
        
        fetchUserData(userId: user.uid)
    }
    
    func fetchUserData(userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { document, _ in
            if let data = document?.data() {
                firstName = data["firstName"] as? String ?? ""
                lastName = data["lastName"] as? String ?? ""
                isAdmin = data["isAdmin"] as? Bool ?? false
                subcontractor = data["employer"] as? String ?? "no subcontractor selected"
                job = data["jobRole"] as? String ?? "no job selected"
                phoneNumber = data["phoneNumber"] as? String ?? "no phone number"
                MFAEnabled = data["MFAEnabled"] as? Bool ?? false
                
                
                username = "\(firstName) \(lastName)"
            }
        }
    }
    
    
//
//    private func verifyCode() {
//        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
//        
//        let credential = PhoneAuthProvider.provider().credential(
//            withVerificationID: verificationID,
//            verificationCode: enteredCode
//        )
//        
//        Auth.auth().signIn(with: credential) { authResult, error in
//            if let error = error {
//                errorMessage = error.localizedDescription
//                return
//            }
//            
//            // Proceed with account creation after successful phone verification
//            createAccount()
//        }
//    }
    
    
        
        
        
    
    
    
    fileprivate func QualificationsSheet() -> some View {
        return ZStack {
            // Animated card sheet
            VStack {
                HStack {
                    Text("Qualifications")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                }
                
//                Text("Upload your qualifications here")
//                    .font(.subheadline)
                
                Divider()
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                
                Spacer()
                
                Button("Dismiss") {
                    cardShowing = false // Toggle `cardShowing`
//                    withAnimation(.spring()) {
//                        isShowingQualificationsSheet = false
//                    }
                    isShowingQualificationsSheet = false
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .padding()
            .frame(width: animateSheet ? 380 : 0, height: animateSheet ? 500 : 0)
            .background(Color.blue)
            .cornerRadius(20)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animateSheet = true
                }
            }
            .onDisappear {
                animateSheet = false
            }
        }
        .animation(nil, value: isShowingQualificationsSheet) // Prevent global animations
        .transition(.scale)
    }
    
    
    
    
    
    fileprivate func AsbestosSheet() -> some View {
        return ZStack {
            VStack {
                HStack {
                    Text("Asbestos Documentation")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    Image(systemName: "doc.text.fill")
                        .font(.largeTitle)
                }
                
                Divider()
                
                Text("Upload your Asbestos Certifications here")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                ScrollView() {
                    // Display uploaded files
                    ForEach(asbestosImages) { identifiableImage in
                        VStack {
                            Image(uiImage: identifiableImage.image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(10)
                                .padding()
                                .onTapGesture {
                                    selectedImageForViewing = identifiableImage
                                    isImageViewerPresented = true
                                }
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Expiry Date:")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Text(formattedExpiryDate(identifiableImage.expiryDate))
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    // Show the DatePicker when this button is clicked
                                    showExpiryDatePicker = true
                                }) {
                                    Image(systemName: "calendar.badge.clock")
                                }
                                .padding()
                                .background(Circle().fill(Color.white))
                                .foregroundColor(.orange)
                                .cornerRadius(50)
                                
                                Button(action: {
                                    deleteImage(identifiableImage, fileType: .asbestos)
                                }) {
                                    Image(systemName: "trash")
                                }
                                .padding()
                                .background(Circle().fill(Color.white))
                                .foregroundColor(.orange)
                                .cornerRadius(50)
                            }.sheet(isPresented: $showExpiryDatePicker) {
                                VStack {
                                    Text("Select Expiry Date")
                                        .font(.headline)
                                        .padding()
                                    DatePicker("Select Expiry Date", selection: $selectedExpiryDate, in: Date()..., displayedComponents: [.date])
                                        .padding()
                                    Button("Save Expiry Date") {
                                        // Save the expiry date for the image
                                        updateExpiryDateForImage(identifiableImage, newExpiryDate: selectedExpiryDate)
                                        showExpiryDatePicker = false
                                    }
                                    .padding()
                                }
                            }
                        }
                    }.fullScreenCover(item: $selectedImageForViewing) { identifiableImage in
                        ImageViewer(image: identifiableImage.image)
                    }

                    ForEach(asbestosPDFs, id: \.self) { pdfURL in
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.white)
                            Text(pdfURL.lastPathComponent)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Upload buttons
                HStack {
                    Button(action: { showImagePicker = true }) {
                        Label("Upload Image", systemImage: "photo.on.rectangle")
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                    
                    Button(action: { showPDFPicker = true }) {
                        Label("Upload PDF", systemImage: "doc.text")
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button("Dismiss") {
                    cardShowing = false
                    isAsbestosShowing = false
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.orange)
                .cornerRadius(8)
            }
            .padding()
            .frame(width: animateSheet ? 380 : 0, height: animateSheet ? 500 : 0)
            .background(Color.orange)
            .cornerRadius(20)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animateSheet = true
                }
            }
            .onDisappear {
                animateSheet = false
            }
        }
        .onAppear {
            loadFiles(fileType: .asbestos)
        }
        .animation(nil, value: isAsbestosShowing) // Prevent global animations
        .transition(.scale)
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let image = selectedImage, let imageURL = saveImage(image, fileType: .asbestos) {
                let identifiableImage = IdentifiableImage(image: image, filePath: imageURL, expiryDate: selectedExpiryDate)
                asbestosImages.append(identifiableImage)
            }
            loadFiles(fileType: .asbestos)
        }) {
            ImagePicker(selectedImage: $selectedImage)
        }

        .sheet(isPresented: $showPDFPicker, onDismiss: {
            if let pdf = selectedPDF {
                asbestosPDFs.append(pdf)
                savePDF(pdf) // Save locally
                selectedPDF = nil
            }
        }) {
            PDFPicker(selectedPDF: $selectedPDF)
        }
    }
    
    fileprivate func InductionSheet() -> some View {
        return ZStack {
            // Animated card sheet
            VStack {
                HStack {
                    Text("Induction Confirmation")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    Image(systemName: "checkmark.seal")
                        .font(.largeTitle)
                }
                
//                Text("Upload your qualifications here")
//                    .font(.subheadline)
                
                Divider()
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                
                Spacer()
                
                Button("Dismiss") {
                    cardShowing = false // Toggle `cardShowing`
                    isInductionShowing = false
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            .padding()
            .frame(width: animateSheet ? 380 : 0, height: animateSheet ? 500 : 0)
            .background(Color.red)
            .cornerRadius(20)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animateSheet = true
                }
            }
            .onDisappear {
                animateSheet = false
            }
        }
        .animation(nil, value: isInductionShowing) // Prevent global animations
        .transition(.scale)
    }
    
    fileprivate func FaceFitSheet() -> some View {
        return ZStack {
            VStack {
                HStack {
                    Text("Face Fit")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    Image(systemName: "face.dashed")
                        .font(.largeTitle)
                }
                
                Divider()
                
                Text("Upload your Face Fit Certifications here")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                ScrollView() {
                    // Display uploaded files
                    ForEach(faceFitImages) { identifiableImage in
                        VStack {
                            Image(uiImage: identifiableImage.image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(10)
                                .padding()
                                .onTapGesture {
                                    selectedImageForViewing = identifiableImage
                                    isImageViewerPresented = true
                                }
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Expiry Date:")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Text(formattedExpiryDate(identifiableImage.expiryDate))
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    // Show the DatePicker when this button is clicked
                                    showExpiryDatePicker = true
                                }) {
                                    Image(systemName: "calendar.badge.clock")
                                }
                                .padding()
                                .background(Circle().fill(Color.white))
                                .foregroundColor(.purple)
                                .cornerRadius(50)
                                
                                Button(action: {
                                    deleteImage(identifiableImage, fileType: .faceFit)
                                }) {
                                    Image(systemName: "trash")
                                }
                                .padding()
                                .background(Circle().fill(Color.white))
                                .foregroundColor(.purple)
                                .cornerRadius(50)
                                
                                
                                
                                
                                
                            }.sheet(isPresented: $showExpiryDatePicker) {
                                VStack {
                                    Text("Select Expiry Date")
                                        .font(.headline)
                                        .padding()
                                    DatePicker("Select Expiry Date", selection: $selectedExpiryDate, in: Date()..., displayedComponents: [.date])
                                        .padding()
                                    Button("Save Expiry Date") {
                                        // Save the expiry date for the image
                                        updateExpiryDateForImage(identifiableImage, newExpiryDate: selectedExpiryDate)
                                        showExpiryDatePicker = false
                                    }
                                    .padding()
                                }
                            }
                        }
                        
                    }.fullScreenCover(item: $selectedImageForViewing) { identifiableImage in
                        ImageViewer(image: identifiableImage.image)
                    }

                    ForEach(faceFitPDFs, id: \.self) { pdfURL in
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.white)
                            Text(pdfURL.lastPathComponent)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Upload buttons
                HStack {
                    Button(action: { showImagePicker = true }) {
                        Label("Upload Image", systemImage: "photo.on.rectangle")
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                    
                    Button(action: { showPDFPicker = true }) {
                        Label("Upload PDF", systemImage: "doc.text")
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                    
                }
                
                Spacer()
                
                Button("Dismiss") {
                    cardShowing = false
                    isShowingFaceFitSheet = false
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.purple)
                .cornerRadius(8)
            }
            .padding()
            .frame(width: animateSheet ? 380 : 0, height: animateSheet ? 500 : 0)
            .background(Color.purple)
            .cornerRadius(20)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animateSheet = true
                }
            }
            .onDisappear {
                animateSheet = false
            }
        }
        .onAppear {
            loadFiles(fileType: .faceFit)
        }
        .animation(nil, value: isShowingFaceFitSheet) // Prevent global animations
        .transition(.scale)
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let image = selectedImage, let imageURL = saveImage(image, fileType: .faceFit) {
                let identifiableImage = IdentifiableImage(image: image, filePath: imageURL, expiryDate: selectedExpiryDate)
                faceFitImages.append(identifiableImage)
            }
            loadFiles(fileType: .faceFit)
        }) {
            ImagePicker(selectedImage: $selectedImage)
        }

        .sheet(isPresented: $showPDFPicker, onDismiss: {
            if let pdf = selectedPDF {
                faceFitPDFs.append(pdf)
                savePDF(pdf) // Save locally
                selectedPDF = nil
            }
        }) {
            PDFPicker(selectedPDF: $selectedPDF)
        }
    }
    
    @State private var showExpiryDatePicker = false // Flag to show the expiry date picker

    // Function to update the expiry date for an image
    func updateExpiryDateForImage(_ image: IdentifiableImage, newExpiryDate: Date) {
        if let index = asbestosImages.firstIndex(where: { $0.id == image.id }) {
            asbestosImages[index].expiryDate = newExpiryDate
            // Save the expiry date to a metadata file
            saveExpiryDate(for: image.filePath, expiryDate: newExpiryDate)
        }
    }
    
    func saveExpiryDate(for imageURL: URL, expiryDate: Date) {
        let metadataURL = imageURL.deletingPathExtension().appendingPathExtension("txt")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let expiryDateString = dateFormatter.string(from: expiryDate)

        do {
            try expiryDateString.write(to: metadataURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save expiry date: \(error.localizedDescription)")
        }
    }
    
    func formattedExpiryDate(_ date: Date?) -> String {
        guard let date = date else { return "No expiry date" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return dateFormatter.string(from: date)
    }
    
    
    func loadFiles(fileType: FileType) {
        let directory = getDirectory(for: fileType)
        
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            switch fileType {
            case .asbestos:
                asbestosImages = files.compactMap { url in
                    if let uiImage = UIImage(contentsOfFile: url.path) {
                        let expiryDate: Date? = loadExpiryDate(for: url, fileType: .asbestos)
                        return IdentifiableImage(image: uiImage, filePath: url, expiryDate: expiryDate)
                    }
                    return nil
                }
            case .faceFit:
                faceFitImages = files.compactMap { url in
                    if let uiImage = UIImage(contentsOfFile: url.path) {
                        let expiryDate: Date? = loadExpiryDate(for: url, fileType: .faceFit)
                        return IdentifiableImage(image: uiImage, filePath: url, expiryDate: expiryDate)
                    }
                    return nil
                }
            }
        }
    }
    
    func loadExpiryDate(for imageURL: URL, fileType: FileType) -> Date? {
        let metadataURL = imageURL.deletingPathExtension().appendingPathExtension("txt")
        
        if let metadataContent = try? String(contentsOf: metadataURL, encoding: .utf8) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: metadataContent)
        }
        return nil
    }

    // Save files when a new image or PDF is uploaded
    func saveImage(_ image: UIImage, fileType: FileType) -> URL? {
        let directory = getDirectory(for: fileType)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let imageName = UUID().uuidString + ".png"
        let imageURL = directory.appendingPathComponent(imageName)
        
        if let data = image.pngData() {
            try? data.write(to: imageURL)
            return imageURL // Return the image URL
        }
        return nil
    }
    
    func getDirectory(for fileType: FileType) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        switch fileType {
        case .asbestos:
            return documentsDirectory.appendingPathComponent("AsbestosFiles")
        case .faceFit:
            return documentsDirectory.appendingPathComponent("FaceFitFiles")
        }
    }
    
    
    func deleteImage(_ identifiableImage: IdentifiableImage, fileType: FileType) {
        do {
            if FileManager.default.fileExists(atPath: identifiableImage.filePath.path) {
                try FileManager.default.removeItem(at: identifiableImage.filePath)
                print("Deleted image at: \(identifiableImage.filePath.path)")
            }
            
            // Remove the image from the in-memory array
            switch fileType {
            case .asbestos:
                if let index = asbestosImages.firstIndex(where: { $0.id == identifiableImage.id }) {
                    asbestosImages.remove(at: index)
                }
            case .faceFit:
                if let index = faceFitImages.firstIndex(where: { $0.id == identifiableImage.id }) {
                    faceFitImages.remove(at: index)
                }
            }
        } catch {
            print("Error deleting image: \(error)")
        }
    }

    func savePDF(_ pdfURL: URL) {
        let pdfsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("FaceFitPDFs")
        try? FileManager.default.createDirectory(at: pdfsDirectory, withIntermediateDirectories: true)

        let pdfName = UUID().uuidString + ".pdf"
        let destinationURL = pdfsDirectory.appendingPathComponent(pdfName)

        try? FileManager.default.copyItem(at: pdfURL, to: destinationURL)
    }
}

enum FileType {
    case asbestos
    case faceFit
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let filePath: URL
    var expiryDate: Date?
}

struct ImageViewer: View {
    let image: UIImage

    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            Spacer()
            Button("Close") {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}


struct PDFPicker: UIViewControllerRepresentable {
    @Binding var selectedPDF: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: PDFPicker

        init(_ parent: PDFPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedPDF = urls.first
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // Allow only images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            if let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}




class AddressViewModel: ObservableObject {
    @Published var addresses = [Address]()
    @Published var searchQuery = ""
    
    private var db = Firestore.firestore()
    
    func fetchAddresses() {
        print("Fetching addresses from Firestore...")  // Debugging statement
        db.collection("addresses").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching addresses: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = querySnapshot else {
                print("No addresses found.")
                return
            }
            
            DispatchQueue.main.async {
                // Map the fetched documents to Address objects
                self.addresses = snapshot.documents.compactMap { document in
                    let data = document.data()
                    
                    // Extract data for each field in the address document
                    guard let firstLine = data["firstLine"] as? String,
                          let postcode = data["postcode"] as? String,
                          let asbestosSafe = data["asbestosSafe"] as? Bool else {
                        print("Error parsing address data for document: \(document.documentID)")
                        return nil
                    }
                    
                    // Return Address object
                    print("Document data for \(document.documentID): \(data)")
                    return Address(id: document.documentID, firstLine: firstLine, postcode: postcode, asbestosSafe: asbestosSafe)
                }
                //print("Mapped addresses: \(self.addresses)")  // Debugging statement
            }
        }
    }
    
    // Function to filter addresses based on the search query
    var filteredAddresses: [Address] {
        print("Filtering addresses with query: \(searchQuery)")  // Debugging statement
        if searchQuery.isEmpty {
            return addresses
        } else {
            return addresses.filter { address in
                address.firstLine.lowercased().contains(searchQuery.lowercased()) ||
                address.postcode.lowercased().contains(searchQuery.lowercased())
            }
        }
    }
}


#Preview {
    UserProfile()
}
