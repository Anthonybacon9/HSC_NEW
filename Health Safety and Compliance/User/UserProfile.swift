import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfile: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    @AppStorage("firstName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""
    @AppStorage("uid") var userId: String = "1"
    @AppStorage("isAdmin") var isAdmin: Bool = false
    @AppStorage("subcontractor") var subcontractor: String = ""
    
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
    @State private var selectedSubcontractor: String? = nil
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isAuthenticated {
                ScrollView {
                    VStack(spacing: 25) {
                        profileSection
                        Spacer()
                        if isAdmin { adminSection }
                        accountManagementSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                }
            } else {
                Group {
                    if isCreatingAccount {
                        signUpForm
                    } else {
                        signInForm
                    }
                }
            }
        }
        .onAppear(perform: setup)
    }

    private var profileSection: some View {
        VStack(spacing: 20) {
            // Profile Picture & Username
            HStack {
                Image(systemName: "person.circle.fill") // Placeholder image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .foregroundColor(.green)
                    .padding(.trailing, 20)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(isAdmin ? "Administrator" : "User")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(subcontractor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
            }
            .padding(.top, 20)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.bottom, 20)
        }
    }

    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Admin Tools")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Invite Code Section
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
            .shadow(radius: 5)
            
            // Info Text
            Text("*Generate a code for a subcontractor to distribute to their team.")
                .font(.footnote)
                .foregroundColor(.gray.opacity(0.8))
                .italic()
                .padding(.top, 5)
        }
        .padding(.horizontal, 20)
    }

    private var accountManagementSection: some View {
        VStack(spacing: 20) {
            // Change Password Button
            Button(action: { isShowingPasswordChange = true }) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.white)
                    Text("Change Password")
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
            }
            .padding(.bottom, 10)
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
            
            // Sign Out Button
            Button(action: signOut) {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .foregroundColor(.red)
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 2))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var signUpForm: some View {
        VStack(spacing: 20) {
            Text("Create Account").font(.title).fontWeight(.bold)
            TextField("Invite Code", text: $inviteCode).textFieldStyle(RoundedBorderTextFieldStyle())
            if isShowingInviteCodeError { Text("Invalid or expired invite code.").foregroundColor(.red) }
            TextField("First Name", text: $firstName).textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Last Name", text: $lastName).textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Email", text: $email).textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Confirm Password", text: $confirmPassword).textFieldStyle(RoundedBorderTextFieldStyle())
            Toggle("Are you a subcontractor?", isOn: $isSubcontractor).padding()
            if isSubcontractor {
                Picker("Select Subcontractor", selection: $selectedSubcontractor) {
                    ForEach(subcontractors, id: \.self) { Text($0) }
                }.pickerStyle(MenuPickerStyle()).padding()
            } else {
                Text("Next Energy Employee").foregroundColor(.gray)
            }
            if let error = errorMessage { Text(error).foregroundColor(.red) }
            Button(action: validateInviteCodeAndCreateAccount) { Text("Create Account").padding().background(Color.blue).cornerRadius(8) }
            Button(action: { isCreatingAccount = false }) { Text("Already have an account? Sign In").foregroundColor(.blue) }
        }.padding().onAppear(perform: fetchSubcontractors)
    }
    
    private var signInForm: some View {
        VStack(spacing: 20) {
            Text("Sign In").font(.title).fontWeight(.bold)
            TextField("Email", text: $email).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
            SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
            if let error = errorMessage { Text(error).foregroundColor(.red) }
            Button(action: signIn) { Text("Sign In").padding().background(Color.blue).cornerRadius(8) }
            Button(action: { isCreatingAccount = true }) { Text("Don't have an account? Create one").foregroundColor(.blue) }
        }.padding()
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
        Firestore.firestore().collection("subcontractors").getDocuments { snapshot, _ in
            subcontractors = snapshot?.documents.compactMap { $0["name"] as? String } ?? []
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
            userId = ""
            isAdmin = false
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            if let user = authResult?.user {
                username = user.displayName ?? user.email ?? "Unknown User"
                userId = user.uid
                isAuthenticated = true
                
                fetchUserData(userId: user.uid)
            }
        }
    }
    
    private func createAccount() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let user = authResult?.user else { return }
            let fullName = "\(firstName) \(lastName)"
            
            Firestore.firestore().collection("users").document(user.uid).setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "isAdmin": isAdmin,
                "employer": selectedSubcontractor ?? ""
            ]) { _ in
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                changeRequest.commitChanges { error in
                    if error == nil {
                        isAuthenticated = true
                        username = fullName
                    }
                }
            }
        }
    }
    
    private func fetchUserData(userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { document, _ in
            if let data = document?.data() {
                firstName = data["firstName"] as? String ?? ""
                lastName = data["lastName"] as? String ?? ""
                isAdmin = data["isAdmin"] as? Bool ?? false
                subcontractor = data["employer"] as? String ?? "no subcontractor selected"
            }
        }
    }
}

#Preview {
    UserProfile()
}
