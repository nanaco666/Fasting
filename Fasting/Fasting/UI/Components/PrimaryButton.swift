//
//  PrimaryButton.swift
//  Fasting
//
//  主操作按钮组件
//

import SwiftUI

/// 主操作按钮
struct PrimaryButton: View {
    // MARK: - Properties
    
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isDestructive: Bool = false
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headline)
                    }
                    Text(title)
                        .font(.headline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    // MARK: - Private
    
    private var buttonColor: Color {
        if isDestructive {
            return .red
        }
        return .accentColor
    }
}

/// 次级操作按钮
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isDestructive ? .red : .accentColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                (isDestructive ? Color.red : Color.accentColor).opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

/// 圆形操作按钮（用于开始/停止断食）
struct CircularActionButton: View {
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            action()
        }) {
            ZStack {
                // 外圈
                Circle()
                    .stroke(
                        isActive ? Color.red.opacity(0.3) : Color.green.opacity(0.3),
                        lineWidth: 4
                    )
                
                // 内圈
                Circle()
                    .fill(isActive ? Color.red : Color.green)
                    .padding(8)
                
                // 图标
                Image(systemName: isActive ? "stop.fill" : "play.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: isActive ? 0 : 2)  // play 图标需要微调居中
            }
            .frame(width: 80, height: 80)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("Buttons") {
    VStack(spacing: 20) {
        // 主按钮
        PrimaryButton(title: "开始断食", action: {})
        
        PrimaryButton(title: "开始断食", action: {}, icon: "play.fill")
        
        PrimaryButton(title: "结束断食", action: {}, icon: "stop.fill", isDestructive: true)
        
        PrimaryButton(title: "加载中...", action: {}, isLoading: true)
        
        // 次级按钮
        HStack(spacing: 12) {
            SecondaryButton(title: "编辑", action: {}, icon: "pencil")
            SecondaryButton(title: "删除", action: {}, icon: "trash", isDestructive: true)
        }
        
        // 圆形按钮
        HStack(spacing: 40) {
            CircularActionButton(isActive: false, action: {})
            CircularActionButton(isActive: true, action: {})
        }
    }
    .padding()
}
