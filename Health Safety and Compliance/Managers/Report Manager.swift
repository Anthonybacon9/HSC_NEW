//
//  Report Manager.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 14/10/2024.
//

import Foundation

struct Report {
    var firstName: String
    var lastName: String
    var userId: String
    var location: String
    var date: Date
    var type: ReportType
    var description: String
    var severity: String
    var injuryReported: Bool
    var witnessNames: String
    var timeOfAccident: String
    var address: String
    var phoneNumber: String
    var jobTitle: String
    var accidentContract: String
    var lineManager: String
    var employmentDetails: String
    var typeOfReport: String
    var typeOfInjury: String
    var partOfBody: String
    var personGender: String
    var personAge: String
    var actionsTaken: String

    init(
        firstName: String,
        lastName: String,
        userId: String,
        location: String,
        date: Date,
        type: ReportType,
        description: String,
        severity: String,
        injuryReported: Bool,
        witnessNames: String,
        timeOfAccident: String,
        address: String,
        phoneNumber: String,
        jobTitle: String,
        accidentContract: String,
        lineManager: String,
        employmentDetails: String,
        typeOfReport: String,
        typeOfInjury: String,
        partOfBody: String,
        personGender: String,
        personAge: String,
        actionsTaken: String
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.userId = userId
        self.location = location
        self.date = date
        self.type = type
        self.description = description
        self.severity = severity
        self.injuryReported = injuryReported
        self.witnessNames = witnessNames
        self.timeOfAccident = timeOfAccident
        self.address = address
        self.phoneNumber = phoneNumber
        self.jobTitle = jobTitle
        self.accidentContract = accidentContract
        self.lineManager = lineManager
        self.employmentDetails = employmentDetails
        self.typeOfReport = typeOfReport
        self.typeOfInjury = typeOfInjury
        self.partOfBody = partOfBody
        self.personGender = personGender
        self.personAge = personAge
        self.actionsTaken = actionsTaken
    }
}

//MARK: JOB TITLES

struct JobTitle: Identifiable {
    let id = UUID()
    var name: String
}

let jobTitles = [
    JobTitle(name: "Air Source Heat Pump"),
    JobTitle(name: "Boiler / FTCH"),
    JobTitle(name: "Brick Work"),
    JobTitle(name: "Cavity Wall Insulation"),
    JobTitle(name: "Customer Liaison Officer (CLO)"),
    JobTitle(name: "Electric Storage Heaters"),
    JobTitle(name: "Electrician"),
    JobTitle(name: "External Wall Insulation"),
    JobTitle(name: "Flat Roof Insulation"),
    JobTitle(name: "Heating Engineer"),
    JobTitle(name: "Internal Wall Insulation"),
    JobTitle(name: "Joinery"),
    JobTitle(name: "Labourer"),
    JobTitle(name: "Loft Insulation"),
    JobTitle(name: "Plastering"),
    JobTitle(name: "Plumbing"),
    JobTitle(name: "Room and Roof Insulation"),
    JobTitle(name: "Scaffold"),
    JobTitle(name: "Site Manager"),
    JobTitle(name: "Sloping Ceiling Insulation"),
    JobTitle(name: "Solar Installation"),
    JobTitle(name: "Under Floor Insulation"),
    JobTitle(name: "Windows and Door Installation")
]

//MARK: GENDER

struct Gender: Identifiable {
    let id = UUID()
    var name: String
}

let Genders = [
    Gender(name: "Male"),
    Gender(name: "Female"),
    Gender(name: "Other")
]

//MARK: TYPE OF ACCIDENT
struct AccType: Identifiable {
    let id = UUID()
    var name: String
}

let AccTypes = [
    AccType(name: "Manual Handling"),
    AccType(name: "Fall from Height"),
    AccType(name: "Impact or Collision"),
    AccType(name: "Hit by moving object"),
    AccType(name: "Injured by Machinery or Equipment"),
    AccType(name: "Other")
]

//MARK: PART OF BODY
struct BodyPart: Identifiable {
    let id = UUID()
    var name: String
}

let BodyParts = [
    BodyPart(name: "Head"),
    BodyPart(name: "Left Eye"),
    BodyPart(name: "Right Eye"),
    BodyPart(name: "Left Arm"),
    BodyPart(name: "Left Hand"),
    BodyPart(name: "Right Arm"),
    BodyPart(name: "Right Hand"),
    BodyPart(name: "Torso Front"),
    BodyPart(name: "Torso Back"),
    BodyPart(name: "Left Leg"),
    BodyPart(name: "Left Foot"),
    BodyPart(name: "Right Leg"),
    BodyPart(name: "Right Foot"),
]

//MARK: TYPE OF INJURY
struct Injury: Identifiable {
    let id = UUID()
    var name: String
}

let Injuries = [
    Injury(name: "Fatality"),
    Injury(name: "Loss of Consciousness caused by head injury or asphyxia"),
    Injury(name: "Amputation(s)"),
    Injury(name: "Any Injury Likely to lead to loss/reduction of sight"),
    Injury(name: "Any crush injury to the head / torso causing damage to brain / internal organs"),
    Injury(name: "Serious burns, which covers more than 10% of the body or causes significant damage to the eyes, respiratory systems or other vital organs"),
    Injury(name: "Any Scalping requiring hospitalization"),
    Injury(name: "Any other injury arising from working in an enclosed space which... leads to hypothermia, heat-induced illness, requires resuscitation or admittance to hospital for more than 24 hours."),
    Injury(name: "Fracture"),
    Injury(name: "Cuts and Abrasions"),
    Injury(name: "Other"),
]

//MARK: EMPLOYMENT DETAILS

struct Employment: Identifiable {
    let id = UUID()
    var name: String
}

let EmploymentDetails = [
    Employment(name: "Employed"),
    Employment(name: "Subcontractor"),
    Employment(name: "Member of the Public")
]

//MARK: SEVERITY

struct Severity: Identifiable {
    let id = UUID()
    let name: String
}

let Severities = [
    Severity(name: "Minor"),
    Severity(name: "Moderate"),
    Severity(name: "Severe"),
]

//MARK:
