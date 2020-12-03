//
//  AppError+SwiftUI.swift
//  ImagePickerDisplayer
//
//  Created by Neil on 03/12/20.
//

#if canImport(SwiftUI)
import SwiftUI

extension AppError {
    func alert(primaryButton: String = "Ok", primaryAction: @escaping (()->Void) = {}, secondaryButton: String = "Cancel", secondaryAction: @escaping (()->Void) = {}) -> Alert {
        Alert(
            title: Text(self.title ?? ""),
            message: Text(self.message ?? ""),
            primaryButton: .default(Text(primaryButton), action: primaryAction),
            secondaryButton: Alert.Button.cancel(Text(secondaryButton), action: secondaryAction)
        )
    }
}

#endif
