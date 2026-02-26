//
//  SimpleDialView.swift
//  Fasting
//
//  Simple progress ring — the original default timer style
//

import SwiftUI

struct SimpleDialView: View {
    let progress: Double
    let elapsed: TimeInterval
    let target: TimeInterval
    let isFasting: Bool
    let isGoalAchieved: Bool
    
    private let dialSize: CGFloat = 250
    private let ringWidth: CGFloat = 14
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.08), lineWidth: ringWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    isGoalAchieved ? Color.fastingTeal : Color.fastingGreen,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smoothSpring, value: progress)
            
            // Center content
            VStack(spacing: 6) {
                Text(formattedElapsed)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                if isFasting {
                    if isGoalAchieved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .symbolEffect(.bounce, value: isGoalAchieved)
                            Text("COMPLETED")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.fastingGreen)
                        .tracking(1)
                    } else {
                        Text("\(formattedRemaining) · \(Int(progress * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                } else {
                    Text("LAST FAST")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .tracking(1)
                }
            }
        }
        .frame(width: dialSize, height: dialSize)
    }
    
    private var formattedElapsed: String {
        FastingRecord.formatDuration(elapsed)
    }
    
    private var formattedRemaining: String {
        FastingRecord.formatShortDuration(max(target - elapsed, 0))
    }
}
