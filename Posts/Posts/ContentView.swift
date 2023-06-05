//
//  ContentView.swift
//  Posts
//
//  Created by khloud on 15/11/1444 AH.
//

import SwiftUI

struct ContentView: View {
    
    @State var alertMessage = ""
    @State var isAlertShown = false
    @State var isLoading = true
    @State var posts: [Posts] = [ ]
    
    
    func addNewPost() async {
        let newPost = Posts( title: "", body: "")
      
        posts.append(newPost)
        
        await upsertOnePost(post: newPost)
    }
    
    
    
    func upsertOnePost(post: Posts) async {
        
        isLoading = true
        do {
            
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let urlString = "https://jsonplaceholder.typicode.com/posts"
            let request = try urlString.toRequest(withBody: post, method: "PUT")
            let result = try await callApi(request, to: DeleteTodoApiResponse.self)
            
            posts = result.newPost
    
        } catch {
            print("Error: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteOnePost(postId: String) async {
        
        isLoading = true
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let urlString = "https://jsonplaceholder.typicode.com/posts/" + postId
            let request = try urlString.toDeleteRequest()
            let result = try await callApi(request, to: DeleteTodoApiResponse.self)
            posts = result.newPost
            if !result.success {
                alertMessage = result.message
                isAlertShown = true
            }
            
        } catch {
            print("Error: \(error)")
        }
        isLoading = false
    }
    
    
    func fetchPosts() async {
        
        isLoading = true
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let urlString = "https://jsonplaceholder.typicode.com/posts/all"
            let request = try urlString.toRequest()
            let apiPosts = try await callApi(request, to: [Posts].self)
            posts = apiPosts
        } catch {
            print("Error: \(error)")
        }
        isLoading = false
    }
    
    
    var body: some View {
        VStack {
            
            Button("Add Todo") { Task { await addNewPost() } }
            Button("Refresh") {
                Task {
                    await fetchPosts()
                }
            }
            if (isLoading) {
                ProgressView()
            }
            
            
            List {
                ForEach(posts) { post in
                    PostView(post: post, onTitleChange: { newTitle in
                        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
                            return
                        }
                                                
                        let updatedPost = Posts( title: newTitle , body: post.body)
                        posts[index] = updatedPost
                        Task {
                            await upsertOnePost(post: updatedPost)
                        }
                        
                        
                        
                        
                    }, onBodyChange: { newBody in
                        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
                            return
                        }
                   
                        let updatedPost = Posts( title: post.title, body: newBody)
                        posts[index] = updatedPost
                        Task {
                            await upsertOnePost(post: updatedPost)
                        }
                    })
                }
                .onDelete { index in
                    let deletedPostId = index.map { posts[$0].id }.first ?? ""
                    posts.remove(atOffsets: index)
                    Task {
                        await deleteOnePost(postId: deletedPostId)
                    }
                }
            }
            .alert(alertMessage, isPresented: $isAlertShown, actions: {})
        }
        
        .task {
            await fetchPosts()
        
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct Posts: Identifiable, Codable {
    let title: String
    let body: String
    
    var id: String {
        title + body
        
    }
    
}

struct DeleteTodoApiResponse: Codable {
    let success: Bool
    let newPost: [Posts]
    let message: String
}

struct PostView: View {
    
    let post: Posts
    let onTitleChange: (String) -> Void
    let onBodyChange: (String) -> Void
    
    @State var taskTitle = ""
    
    var body: some View  {
        HStack {
            TextField("", text: $taskTitle)
                .onChange(of: taskTitle) {
                    onTitleChange($0)
                }
            
            Spacer()
            
            Image(systemName:"Person")
                .onTapGesture {
                }.onAppear {
                    taskTitle = post.title
                }
        }
    }
}
