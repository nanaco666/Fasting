//
//  ProgressRing.swift
//  Fasting
//
//  Apple Fitness 风格的圆形进度环
//

import SwiftUI

/// 进度环视图
struct ProgressRing: View {
    // MARK: - Properties
    
    /// 进度值 (0.0 - 1.0)
    let progress: Double
    
    /// 环的粗细
    var lineWidth: CGFloat = 20
    
    /// 渐变颜色
    var gradientColors: [Color] = [.green, .blue]
    
    /// 背景环颜色
    var backgroundOpacity: Double = 0.2
    
    /// 是否显示动画
    var animated: Bool = true
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 背景环
            Circle()
                .stroke(
                    Color.gray.opacity(backgroundOpacity),
                    lineWidth: lineWidth
                )
            
            // 进度环
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors + [gradientColors.first ?? .green]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(animated ? .spring(response: 0.6, dampingFraction: 0.8) : nil, value: progress)
            
            // 终点圆点（当有进度时显示）
            if progress > 0.01 {
                Circle()
                    .fill(gradientColors.last ?? .blue)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -ringRadius)
                    .rotationEffect(.degrees(360 * min(progress, 1.0)))
                    .animation(animated ? .spring(response: 0.6, dampingFraction: 0.8) : nil, value: progress)
            }
        }
    }
    
    // MARK: - Private
    
    private var ringRadius: CGFloat {
        // 这个值会在实际布局时根据容器大小计算
        // 这里使用一个占位值，实际使用时需要通过 GeometryReader 计算
        100
    }
}

/// 带中心内容的进度环
struct ProgressRingWithContent<Content: View>: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradientColors: [Color]
    @ViewBuilder let content: () -> Content
    
    init(
        progress: Double,
        lineWidth: CGFloat = 20,
        gradientColors: [Color] = [.green, .blue],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradientColors = gradientColors
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = (size - lineWidth) / 2
            
            ZStack {
                // 背景环
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: lineWidth
                    )
                
                // 进度环
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors + [gradientColors.first ?? .green]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                
                // 终点圆点
                if progress > 0.01 {
                    Circle()
                        .fill(gradientColors.last ?? .blue)
                        .frame(width: lineWidth, height: lineWidth)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(360 * min(progress, 1.0)))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
                
                // 中心内容
                content()
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - Preview

#Preview("Progress Ring") {
    VStack(spacing: 40) {
        ProgressRing(progress: 0.75)
            .frame(width: 200, height: 200)
        
        ProgressRingWithContent(
            progress: 0.65,
            lineWidth: 24,
            gradientColors: [.orange, .red]
        ) {
            VStack(spacing: 4) {
                Text("65%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("断食中")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 250, height: 250)
    }
    .padding()
}
