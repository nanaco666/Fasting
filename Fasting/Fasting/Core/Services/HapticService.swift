//
//  HapticService.swift
//  Fasting
//
//  Haptic feedback utility for enhanced user experience
//

import UIKit

enum Haptic {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}