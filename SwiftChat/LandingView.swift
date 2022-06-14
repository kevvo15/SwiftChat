//
//  ContentView.swift
//  SwiftChat
//
//  Created by Kevin Sandoval on 6/13/22.
//

import SwiftUI
import Firebase

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        
        super.init()
    }
    
}

struct LandingView: View {
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var showImagePicker = false
    @State private var image: UIImage?
    
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
                            showImagePicker
                                .toggle()
                        } label: {
                            
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size:64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black, lineWidth: 3))
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
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .background(Color(.init(white:0, alpha: 0.05))
                .ignoresSafeArea())
            .navigationTitle("Swift Chat")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)        }
    }
    
    private func handleAction() {
        if isLoginMode {
            print("Login to firebase with existing creds")
            loginUser()
        } else {
            print("Register new account with firebase auth")
            createNewAccount()
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, error in
            if let err = error {
                print("Failed to create new user: ", err)
                self.loginStatusMessage = "Failed to create a new user: \(err)"
                return
            }
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = ("Successfully created user: \(result?.user.uid ?? "")")
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else { return }
        
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve download URL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
            }
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, error in
            if let err = error {
                print("Failed to sign in user: ", err)
                self.loginStatusMessage = "Failed to sign in user: \(err)"
                return
            }
            
            print("Successfully signed in user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = ("Successfully signed in user: \(result?.user.uid ?? "")")
        }
    }
    
}

struct ContentView_Previews1: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}
