//
//  ContentView.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 03/10/2024.
//

import SwiftUI
import CoreLocation

//MARK: TO DO
//When not signed in, open popover on loadup
//store all user information securely in the database
//have a dropdown menu for all subcontractors, and use the database to display active subcontractors.
//Accident reporting - autofills data saved from user profile



struct ContentView: View {
    init() {
        setupTabBarAppearance()
    }
    
    @State private var selectedTab = 0
    @AppStorage("isAdmin") var isAdmin: Bool = false
    @AppStorage("username") var username: String = "" // Add username storage
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false // Add logged-in status storage
    @State private var loginError: String?
    
    var body: some View {
//        NavigationView {
            ZStack {
                VStack {
                    HStack {
                        Image("image001")
                            .resizable()
                            .frame(width: 100, height: 35)
                            .foregroundStyle(.green)
//                        Text("NextEnergy")
//                            .font(Font.custom("Poppins-Medium", size: 18))
//                            .fontWeight(.bold)
//                            .foregroundStyle(.green)
                        
                    }
                    .frame(width: 380, height: 50)
                        .padding(.vertical, 1)
                    
                    TabView(selection: $selectedTab) {
                        SignIn()
                            .tabItem {
                                Label("Register", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tag(0)
                            .onAppear() {
                                
                            }
                        
//                        ReportForm()
//                            .tag(1)
//                            .tabItem {
//                                Label("Report", systemImage: "bandage.fill")
//                            }
                        
                        UserProfile()
                            .tag(2)
                            .tabItem {
                                Label("Profile", systemImage: "person.fill")
                            }
                    }.accentColor(.green)
                }
                
                
                
                Spacer()
                
            }.navigationBarTitleDisplayMode(.inline)
                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Image(systemName: "person.fill")
//                            .padding(10)
//                            .foregroundStyle(.green)
//                    }
                    ToolbarItem(placement: .principal) { // This places content in the center
                        Image("NEPng")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.green)
                            
                    }
                }
//        }.accentColor(.orange)
    }
    private func setupTabBarAppearance() {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black // Set the background color of the tab bar

            // Customize selected and unselected tab bar item colors
            UITabBar.appearance().tintColor = UIColor.systemGreen // Selected item color
            UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray // Unselected item color
            
            // Apply to all tab bars
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
}


#Preview {
    ContentView()
}
