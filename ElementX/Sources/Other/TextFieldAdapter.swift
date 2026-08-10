//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import UIKit

/// When leveraging introspection, this allows intercepting UITextFieldDelegate calls
class TextFieldAdapter: NSObject, UITextFieldDelegate {
    var textField: UITextField? {
        didSet {
            oldValue?.delegate = nil
            passthroughDelegate = textField?.delegate
            textField?.delegate = self
        }
    }
    
    /// the original swiftui delegate
    private var passthroughDelegate: UITextFieldDelegate?
    
    private let keystrokeSubject = PassthroughSubject<String, Never>()
    /// fires when keystrokes are made. does not fire for deletions or programmatic text changes
    var keystrokePublisher: AnyPublisher<String, Never> {
        keystrokeSubject.eraseToAnyPublisher()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRanges ranges: [NSValue], replacementString string: String) -> Bool {
        guard let range = ranges.first?.rangeValue else { return true }
        if string.isEmpty == false { // don't fire for backspaces
            let previousText = textField.text ?? ""
            
            let completeString = (previousText as NSString).replacingCharacters(in: range, with: string)
            
            keystrokeSubject.send(completeString)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.textField(textField, shouldChangeCharactersInRanges: [NSValue(range: range)], replacementString: string)
    }
    
    // MARK: - Passthrough
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        passthroughDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        passthroughDelegate?.textFieldDidBeginEditing?(textField)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        passthroughDelegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        passthroughDelegate?.textFieldDidEndEditing?(textField, reason: reason)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        passthroughDelegate?.textFieldDidEndEditing?(textField)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        passthroughDelegate?.textFieldShouldClear?(textField) ?? true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        passthroughDelegate?.textFieldShouldReturn?(textField) ?? true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        passthroughDelegate?.textFieldDidChangeSelection?(textField)
    }
    
    @available(iOS 26.0, *)
    func textField(_ textField: UITextField, editMenuForCharactersInRanges ranges: [NSValue], suggestedActions: [UIMenuElement]) -> UIMenu? {
        passthroughDelegate?.textField?(textField, editMenuForCharactersInRanges: ranges, suggestedActions: suggestedActions)
    }
    
    func textField(_ textField: UITextField, editMenuForCharactersIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        passthroughDelegate?.textField?(textField, editMenuForCharactersIn: range, suggestedActions: suggestedActions)
    }
    
    func textField(_ textField: UITextField, willPresentEditMenuWith animator: any UIEditMenuInteractionAnimating) {
        passthroughDelegate?.textField?(textField, willPresentEditMenuWith: animator)
    }
    
    func textField(_ textField: UITextField, willDismissEditMenuWith animator: any UIEditMenuInteractionAnimating) {
        passthroughDelegate?.textField?(textField, willDismissEditMenuWith: animator)
    }
    
    func textField(_ textField: UITextField, insertInputSuggestion inputSuggestion: UIInputSuggestion) {
        passthroughDelegate?.textField?(textField, insertInputSuggestion: inputSuggestion)
    }
}
