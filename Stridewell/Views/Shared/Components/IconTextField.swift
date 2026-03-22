//
//  IconTextField.swift
//  Stridewell
//
//  Styled text field with a leading SF Symbol icon.
//  Supports password show/hide toggle when isPassword is true.
//

import SwiftUI

struct IconTextField: View {

    // MARK: - Properties

    let hint: String
    let symbol: String
    var isPassword: Bool = false
    @Binding var value: String

    // MARK: - Private State

    @State private var showPassword = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Group {
                if isPassword && !showPassword {
                    SecureField(hint, text: $value)
                } else {
                    TextField(hint, text: $value)
                        .keyboardType(symbol == "envelope" ? .emailAddress : .default)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            if isPassword {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(AppColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
    }
}
