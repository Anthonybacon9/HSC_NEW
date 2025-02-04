import SwiftUI



struct ReportForm: View {
    @AppStorage("firstName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""
    @AppStorage("uid") var userId: String = ""
    @AppStorage("isAdmin") var isAdmin: Bool = false
    
    @State private var selectedContract: Contract?
    @State private var selectedJob: JobTitle?
    @State private var selectedGender: Gender?
    @State private var selectedType: AccType?
    @State private var selectedBodyPart: BodyPart?
    @State private var selectedInjury: Injury?
    @State private var selectedEmployment: Employment?
    @State private var selectedSeverity: Severity?

    @State private var report: ReportType = .accident
    @State private var accidentDescription: String = ""
    @State private var incidentDetails: String = ""
    @State private var nearMissDetails: String = ""
    @State private var s1Details: String = ""
    @State private var location: String = ""
    @State private var date: Date = Date()
    @State private var severity: String = ""
    @State private var witnessNames: String = ""
    @State private var injuryReported: Bool = false
    @State private var timeOfAccident: String = ""
    @State private var address: String = ""
    @State private var phoneNumber: String = ""
    @State private var jobTitle: String = ""
    @State private var accidentContract: String = ""
    @State private var lineManager: String = ""
    @State private var employmentDetails: String = ""
    @State private var typeOfReport: String = ""
    @State private var typeOfInjury: String = ""
    @State private var partOfBody: String = ""
    @State private var personGender: String = ""
    @State private var personAge: String = ""
    @State private var actionsTaken: String = ""
    
    @State private var reviewSheetShowing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Picker("Report Type", selection: $report) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(report.rawValue)
                    .font(.headline)
                    .padding(.top)
                
                TextField("Forename", text: $firstName)
                    .padding()
                    .autocapitalization(.none)
                    .background(RoundedRectangle(cornerRadius: 10).stroke())
                    .disabled(true)
                
                TextField("Surname", text: $lastName)
                    .padding()
                    .autocapitalization(.none)
                    .background(RoundedRectangle(cornerRadius: 10).stroke())
                    .disabled(true)
                
                TextField("Location", text: $location)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke())
                
                DatePicker("Date of Report", selection: $date, displayedComponents: .date)
                    .padding()
                
                switch report {
                case .accident:
                    AccidentQuestions()
                case .incident:
                    IncidentQuestions()
                case .nearMiss:
                    NearMissQuestions()
                case .s1:
                    s1Questions()
                }
                
                //action: submitReport
                
                // Submit Button
                Button(action: {
                    reviewSheetShowing = true
                }) {
                    Text("Submit Report")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.top)
                .sheet(isPresented: $reviewSheetShowing) {
                    ReviewReportView()
                }
                .onAppear(
                    perform: fetchContractsFromFirebase
                )
                
                Spacer()
            }
            .padding(10)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    
    
    private func ReviewReportView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Main Title
                Text("Review Report")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                
                SectionHeader(title: "\(report.rawValue)")
                
                // Section: Who / Where / When
                SectionHeader(title: "Who")
                Group {
                    ReviewField(label: "Name", value: "\(firstName) \(lastName)")
                    ReviewField(label: "Job Title", value: selectedJob?.name ?? jobTitle)
                    ReviewField(label: "Employment Details", value: selectedEmployment?.name ?? employmentDetails)
                    ReviewField(label: "Age", value: personAge)
                    ReviewField(label: "Address", value: address)
                    ReviewField(label: "Gender", value: selectedGender?.name ?? personGender)
                    ReviewField(label: "Line Manager", value: lineManager)
                    ReviewField(label: "Phone Number", value: phoneNumber)
                    ReviewField(label: "Location", value: location)
                    ReviewField(label: "Date", value: date, formatter: dateFormatter)
                    ReviewField(label: "Time of Accident", value: timeOfAccident)
                    ReviewField(label: "Witness Names", value: witnessNames)
                }
                .padding(.vertical, 10)

                Divider() // Visual separator between sections
                
                // Section: What
                SectionHeader(title: "What")
                Group {
                    ReviewField(label: "Selected Contract", value: selectedContract?.name ?? "Not selected")
                    ReviewField(label: "Severity", value: selectedSeverity?.name ?? severity)
                    if report.rawValue == "Accident" {
                        ReviewField(label: "Accident Description", value: accidentDescription)
                    }
                    if report.rawValue == "Near Miss" {
                        ReviewField(label: "Near Miss Details", value: nearMissDetails)
                    }
                    if report.rawValue == "Incident" {
                        ReviewField(label: "Incident Details", value: incidentDetails)
                    }
                    ReviewField(label: "Location", value: location)
                    ReviewField(label: "Date", value: date, formatter: dateFormatter)
                    ReviewField(label: "Time of Accident", value: timeOfAccident)
                    ReviewField(label: "Witness Names", value: witnessNames)
                    ReviewField(label: "Injury Reported", value: injuryReported ? "Yes" : "No")
                    ReviewField(label: "Accident Contract", value: accidentContract)
                    ReviewField(label: "Type of Injury", value: selectedInjury?.name ?? typeOfInjury)
                    ReviewField(label: "Part of Body Affected", value: selectedBodyPart?.name ?? partOfBody)
                    ReviewField(label: "Actions Taken", value: actionsTaken)
                }
                .padding(.vertical, 10)
                
                Spacer()
                
                // Confirm Button
                Button(action: {
                    submitReport()
                    print("Report submitted!")
                    reviewSheetShowing = false
                }) {
                    Text("Confirm Submission")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    

    private func submitReport() {
        let report = Report(
            firstName: firstName,
            lastName: lastName,
            userId: userId,
            location: location,
            date: date,
            type: report,
            description: getDescriptionForReportType(),
            severity: selectedSeverity?.name ?? "No Severity Selected",
            injuryReported: injuryReported,
            witnessNames: witnessNames,
            timeOfAccident: timeOfAccident,
            address: address,
            phoneNumber: phoneNumber,
            jobTitle: selectedJob?.name ?? "No Job Selected",
            accidentContract: selectedContract?.name ?? "No Contract Selected",
            lineManager: lineManager,
            employmentDetails: selectedEmployment?.name ?? "No Employment Selected",
            typeOfReport: selectedType?.name ?? "No Type Selected",
            typeOfInjury: selectedInjury?.name ?? "No Injury Selected",
            partOfBody: selectedBodyPart?.name ?? "No Body Part Selected",
            personGender: selectedGender?.name ?? "No Gender Selected",
            personAge: personAge,
            actionsTaken: actionsTaken,
            reportUserID: userId
        )
        
        let firestoreManager = FirestoreManager()
        firestoreManager.addReport(report: report)
    }

    private func getDescriptionForReportType() -> String {
        switch report {
        case .accident:
            return accidentDescription
        case .incident:
            return incidentDetails
        case .nearMiss:
            return nearMissDetails
        case .s1:
            return s1Details
        }
    }
    
    @ViewBuilder
    private func AccidentQuestions() -> some View {
        TextField("Describe the Accident", text: $accidentDescription)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        //MARK: SEVERITY
        Menu {
            ForEach(Severities) { sev in
                Button(action: {
                    selectedSeverity = sev
                }) {
                    Text(sev.name)
                }
            }
        } label: {
            HStack {
                Text(selectedSeverity?.name ?? "Severity")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        Toggle("Was there an injury reported?", isOn: $injuryReported)
            .padding()
        
        TextField("Witness Names (if any)", text: $witnessNames)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Time of the Accident", text: $timeOfAccident)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Your Address", text: $address)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Phone Number", text: $phoneNumber)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        
        //MARK: JOB TITLES
        Menu {
            ForEach(jobTitles) { job in
                Button(action: {
                    selectedJob = job
                }) {
                    Text(job.name)
                }
            }
        } label: {
            HStack {
                Text(selectedJob?.name ?? "Job Title")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //-----------------
        
        //MARK: CONTRACTS
        Menu {
            ForEach(contracts) { contract in
                Button(action: {
                    selectedContract = contract
                }) {
                    Text(contract.name)
                }
            }
        } label: {
            HStack {
                Text(selectedContract?.name ?? "Contract")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        TextField("Who is Your Line Manager?", text: $lineManager)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        //MARK: TYPE OF EMPLOYMENT
        Menu {
            ForEach(EmploymentDetails) { employ in
                Button(action: {
                    selectedEmployment = employ
                }) {
                    Text(employ.name)
                }
            }
        } label: {
            HStack {
                Text(selectedEmployment?.name ?? "Employment Details")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: TYPE OF ACCIDENT
        Menu {
            ForEach(AccTypes) { type in
                Button(action: {
                    selectedType = type
                }) {
                    Text(type.name)
                }
            }
        } label: {
            HStack {
                Text(selectedType?.name ?? "Accident Type")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }

        //MARK: TYPE OF INJURY
        Menu {
            ForEach(Injuries) { injury in
                Button(action: {
                    selectedInjury = injury
                }) {
                    Text(injury.name)
                }
            }
        } label: {
            HStack {
                Text(selectedInjury?.name ?? "Type of Injury")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: BODY PART
        Menu {
            ForEach(BodyParts) { bodyPart in
                Button(action: {
                    selectedBodyPart = bodyPart
                }) {
                    Text(bodyPart.name)
                }
            }
        } label: {
            HStack {
                Text(selectedBodyPart?.name ?? "Part of Body")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: GENDER
        Menu {
            ForEach(Genders) { gender in
                Button(action: {
                    selectedGender = gender
                }) {
                    Text(gender.name)
                }
            }
        } label: {
            HStack {
                Text(selectedGender?.name ?? "Person's Gender")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        
        TextField("Person's Age", text: $personAge)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Describe Actions Taken to Prevent From Happening Again", text: $actionsTaken)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
    }
    
    //MARK: INCIDENTS
    
    @ViewBuilder
    private func IncidentQuestions() -> some View {
        TextField("Describe the Incident", text: $incidentDetails)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        //MARK: SEVERITY
        Menu {
            ForEach(Severities) { sev in
                Button(action: {
                    selectedSeverity = sev
                }) {
                    Text(sev.name)
                }
            }
        } label: {
            HStack {
                Text(selectedSeverity?.name ?? "Severity")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        Toggle("Was there any damage reported?", isOn: $injuryReported)
            .padding()
        
        TextField("Witness Names (if any)", text: $witnessNames)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Time of the Incident", text: $timeOfAccident)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Your Address", text: $address)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Phone Number", text: $phoneNumber)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        //MARK: JOB TITLE
        Menu {
            ForEach(jobTitles) { job in
                Button(action: {
                    selectedJob = job
                }) {
                    Text(job.name)
                }
            }
        } label: {
            HStack {
                Text(selectedJob?.name ?? "Job Title")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: CONTRACTS
        Menu {
            ForEach(contracts) { contract in
                Button(action: {
                    selectedContract = contract
                }) {
                    Text(contract.name)
                }
            }
        } label: {
            HStack {
                Text(selectedContract?.name ?? "Contract")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        TextField("Who is Your Line Manager?", text: $lineManager)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        //MARK: TYPE OF EMPLOYMENT
        Menu {
            ForEach(EmploymentDetails) { employ in
                Button(action: {
                    selectedEmployment = employ
                }) {
                    Text(employ.name)
                }
            }
        } label: {
            HStack {
                Text(selectedEmployment?.name ?? "Employment Details")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: TYPE OF INCIDENT
        Menu {
            ForEach(AccTypes) { type in
                Button(action: {
                    selectedType = type
                }) {
                    Text(type.name)
                }
            }
        } label: {
            HStack {
                Text(selectedType?.name ?? "Incident Type")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: TYPE OF INJURY
        Menu {
            ForEach(Injuries) { injury in
                Button(action: {
                    selectedInjury = injury
                }) {
                    Text(injury.name)
                }
            }
        } label: {
            HStack {
                Text(selectedInjury?.name ?? "Type of Injury")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: BODY PART
        Menu {
            ForEach(BodyParts) { bodyPart in
                Button(action: {
                    selectedBodyPart = bodyPart
                }) {
                    Text(bodyPart.name)
                }
            }
        } label: {
            HStack {
                Text(selectedBodyPart?.name ?? "Part of Body")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        //MARK: GENDER
        Menu {
            ForEach(Genders) { gender in
                Button(action: {
                    selectedGender = gender
                }) {
                    Text(gender.name)
                }
            }
        } label: {
            HStack {
                Text(selectedGender?.name ?? "Person's Gender")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        TextField("Person's Age", text: $personAge)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        TextField("Describe Actions Taken to Prevent From Happening Again", text: $actionsTaken)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
    }
    
    @ViewBuilder
    private func NearMissQuestions() -> some View {
        TextField("Describe the Near Miss", text: $nearMissDetails)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        //MARK: SEVERITY
        Menu {
            ForEach(Severities) { sev in
                Button(action: {
                    selectedSeverity = sev
                }) {
                    Text(sev.name)
                }
            }
        } label: {
            HStack {
                Text(selectedSeverity?.name ?? "Potential Severity")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        Toggle("Was there a safety breach involved?", isOn: $injuryReported)
            .padding()
        
        TextField("Witness Names (if any)", text: $witnessNames)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
    }
    
    //MARK: - SAFETY FIRST OBSERVATIONS
    @ViewBuilder
    private func s1Questions() -> some View {
        TextField("What is your Safety F1rst observation?", text: $nearMissDetails)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
        
        //MARK: SEVERITY
        Menu {
            ForEach(Severities) { sev in
                Button(action: {
                    selectedSeverity = sev
                }) {
                    Text(sev.name)
                }
            }
        } label: {
            HStack {
                Text(selectedSeverity?.name ?? "Potential Severity")
                Image(systemName: "chevron.down")
                Spacer()
            }.padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke())
        }
        
        Toggle("Was there a safety breach involved?", isOn: $injuryReported)
            .padding()
        
        TextField("Witness Names (if any)", text: $witnessNames)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke())
    }
}

enum ReportType: String, CaseIterable {
    case accident = "Accident"
    case incident = "Incident"
    case nearMiss = "Near Miss"
    case s1 = "Safety F1rst Observation"

    var type: String {
        switch self {
        case .accident:
            return "Accident"
        case .incident:
            return "Incident"
        case .nearMiss:
            return "Near Miss"
        case .s1:
            return "Safety F1rst Observation"
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2)
            .bold()
            .foregroundColor(.green)
            .padding(.bottom, 5)
    }
}

struct ReviewField<T>: View {
    let label: String
    let value: T
    var formatter: DateFormatter? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.headline)
                .foregroundColor(.gray)
            if let dateValue = value as? Date, let formatter = formatter {
                Text(formatter.string(from: dateValue))
            } else {
                Text("\(value)")
            }
        }
        .padding(.vertical, 5)
    }
}


#Preview {
    ReportForm()
}
