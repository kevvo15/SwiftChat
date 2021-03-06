//
//  ChatLogView.swift
//  SwiftChat
//
//  Created by Kevin Sandoval on 6/29/22.
//

import SwiftUI
import Firebase

struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let messages = "messages"
    static let recentMessages = "recent_messages"
    static let profileImageUrl = "image_url"
    static let username = "username"
    static let uid = "uid"
}

struct ChatMessage: Identifiable {
    
    var id: String { documentId }
    let documentId: String
    let fromId, toId, text, timestamp: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    
    var chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    var firestoreListener: ListenerRegistration?
    
    func fetchMessages() {
        
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        firestoreListener?.remove()
        chatMessages.removeAll() 
        
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen to messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                        
                    }
                })
                
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let document =
        FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId:fromId, FirebaseConstants.toId:toId, FirebaseConstants.text: self.chatText, FirebaseConstants.timestamp: Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message to Firestore: \(error)"
                return
            }
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument =
        FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message to Firestore: \(error)"
                return
            }
        }
        
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else {
            return
        }

        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .document(toId)
        
        let email = chatUser.email
        let index = email.firstIndex(of: "@") ?? email.endIndex
        let username = email[..<index]
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.username: username
        ] as [String: Any]
        
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print(error)
                return
            }
        }
    }
    
    @Published var count = 0
}

struct ChatLogView: View {
    
//    let chatUser: ChatUser?
//
//    init(chatUser: ChatUser?) {
//        self.chatUser = chatUser
//        self.vm = .init(chatUser: chatUser)
//    }
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
        }
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }.frame(height: 40)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(Color.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private struct DescriptionPlaceholder: View {
        var body: some View {
            HStack {
                Text("What's on your mind?")
                    .foregroundColor(Color(.gray))
                    .font(.system(size: 17))
                    .padding(.leading, 3)
                    .padding(.top, -1)
                Spacer()
            }
        }
    }
    
    static let scrollToBottomId = "Bottom"
    
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { scrollViewProxy in
                VStack {
                    ForEach(vm.chatMessages) { message in
                        ChatMessageView(message: message)
                    }
                    HStack { Spacer() }
                        .id(Self.scrollToBottomId)
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollViewProxy.scrollTo(Self.scrollToBottomId, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.init(white: 0.85, alpha: 1)))
        .safeAreaInset(edge: .bottom) {
            chatBottomBar
                .background(Color(.systemBackground)
                    .ignoresSafeArea())
        }
    }
}

struct ChatMessageView: View {
    
    let message: ChatMessage
    
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(Color(.white))
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(Color(.black))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        //        NavigationView {
        //            ChatLogView(chatUser: .init(data: ["uid": "W78WCHTNICfoKZoeTGwxinqDoDf1", "email": "waterfall@gmail.com"]))
        //        }
        MessageView()
    }
}
