//
//  ContentView.swift
//  ImagePickerDisplayer
//
//  Created by Neil on 03/12/20.
//

import SwiftUI

struct ContentView: View {
    @State private var isPickerPresented: Bool = false
    @State private var selectedImageURL: URL?
    @State private var pickerErrorAlert: Alert!
    @State private var isErrorPresented: Bool = false
    
    var body: some View {
        VStack {
            if let selectedImageURL = self.selectedImageURL, let image = UIImage(contentsOfFile: selectedImageURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 100, height: 100)
            }
            Text("Open Picker")
                .padding()
                .onTapGesture {
                    isPickerPresented.toggle()
                }
                .imagePicker(isPresented: $isPickerPresented) { (result) in
                    self.handleImageSelection(result: result)
                }
                .alert(isPresented: $isErrorPresented, content: {
                    pickerErrorAlert
                })
        }
    }
    
    private func handleImageSelection(result: Result<URL, AppError>) {
        switch result {
        case .success(let imageURL):
            self.selectedImageURL = imageURL
        case .failure(let error):
            self.pickerErrorAlert = error.alert()
            self.isErrorPresented.toggle()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
