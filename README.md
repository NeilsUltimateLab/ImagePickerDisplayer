# ImagePickerDisplayer

UIImagePicker Controller utility project in SwiftUI.

Gist: [ImagePickerDisplayer](https://gist.github.com/NeilsUltimateLab/e158df6a1219505ecb03509b435e17cb)

## Usage

```swift
Text("Open Picker")
    .padding()
    .onTapGesture {
        isPickerPresented.toggle()
    }
    .imagePicker(isPresented: $isPickerPresented) { (result) in
        self.handleImageSelection(result: result)
    }
```
