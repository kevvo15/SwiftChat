//
//  ContentView.swift
//  SwiftChat
//
//  Created by Kevin Sandoval on 6/13/22.
//

import SwiftUI
import Firebase

struct LandingView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some View {
        NavigationView {
            
            ScrollView {
                
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label:
                            Text("Picker Here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            
                        } label: {
                            Image(systemName: "person.fill")
                                .font(.system(size:64))
                                .padding()
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }.padding(12)
                        .background(Color.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size:14, weight: .semibold))
                            Spacer()
                        }.background(Color.blue)
                    }
                }
                .padding()
            }
            .background(Color(.init(white:0, alpha: 0.05))
                .ignoresSafeArea())
            .navigationTitle("Swift Chat")
        }
//        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func handleAction() {
        if isLoginMode {
            print("Login to firebase with existing creds")
        } else {
            print("Register new account with firebase auth")
        }
    }
}

struct ContentView_Previews1: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}
