//
//  MessageView.swift
//  SwiftChat
//
//  Created by Kevin Sandoval on 6/14/22.
//

import SwiftUI
import SDWebImageSwiftUI

class MessageViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    
    init() {
        
        DispatchQueue.main.async {
            self.isCurrentlySignedOut =
            FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else {
            self.errorMessage = "Could not find firebase uid ..."
            return
        }
        
        FirebaseManager.shared.firestore
            .collection("users").document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    self.errorMessage = "failed to get current user:, \(error)"
                    print("failed to get current user:", error)
                    return
                }
                
                guard let data = snapshot?.data()
                else {
                    self.errorMessage = "No data found ..."
                    return
                }
                self.chatUser = .init(data: data)
            }
    }
    
    @Published var isCurrentlySignedOut = false
    func handleSignOut() {
        isCurrentlySignedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
}

struct MessageView: View {
    
    @State private var showLogoutOptions = false
    
    @ObservedObject private var vm = MessageViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messagesView
            }
            .overlay(newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    
    private var customNavBar: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label), lineWidth: 1.5)
                )
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                let email = vm.chatUser?.email ?? ""
                let index = email.firstIndex(of: "@") ?? email.endIndex
                let username = email[..<index]
                Text(username)
                    .font(.system(size: 20, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 12, height: 12)
                    Text("Online")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button {
                showLogoutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .foregroundColor(Color(.label))
                    .font(.system(size: 24, weight: .bold))
            }
        }
        .padding()
        .actionSheet(isPresented: $showLogoutOptions) {
            .init(title: Text("Settings"), message: Text("What would you like to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    print("Handle Sign Out")
                    vm.handleSignOut()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isCurrentlySignedOut, onDismiss: nil) {
            LandingView(completedLoginProcess: {
                self.vm.isCurrentlySignedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 44)
                                .stroke(Color(.label), lineWidth: 1.5)
                            )
                        VStack(alignment: .leading) {
                            Text("Username")
                                .font(.system(size: 16, weight: .bold))
                            Text("Message sent to user")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.lightGray))
                        }
                        Spacer()
                        
                        Text("22d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    @State private var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 10)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView()
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
            .preferredColorScheme(.dark)
        //        MessageView()
    }
}
