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
                }
                
                // Submit Button
                Button(action: submitReport) {
                    Text("Submit Report")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding(10)
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
            actionsTaken: actionsTaken
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
}

enum ReportType: String, CaseIterable {
    case accident = "Accident"
    case incident = "Incident"
    case nearMiss = "Near Miss"

    var type: String {
        switch self {
        case .accident:
            return "Accident"
        case .incident:
            return "Incident"
        case .nearMiss:
            return "Near Miss"
        }
    }
}

#Preview {
    ReportForm()
}
