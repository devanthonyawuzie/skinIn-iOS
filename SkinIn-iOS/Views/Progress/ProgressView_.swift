// Views/Progress/ProgressView_.swift
// SkinIn-iOS
//
// Progress tab — weight trend line chart, strength radar, and detailed lift metrics.
// Named ProgressView_ to avoid collision with SwiftUI's built-in ProgressView.

import SwiftUI
import Charts

// MARK: - ProgressView_

struct ProgressView_: View {

    @State private var vm = ProgressViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ProgressNavBar()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        TrendAnalysisSection(vm: vm)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                        RadarChartSection(vm: vm)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                        DetailedMetricsSection(vm: vm)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.lg)

                        // Clear the custom tab bar
                        Spacer(minLength: 80)
                    }
                }
            }
        }
    }
}

// MARK: - ProgressNavBar

private struct ProgressNavBar: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Progress")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color.black)
                    .accessibilityAddTraits(.isHeader)

                Text("SKININ TRACKER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
                    .kerning(0.5)
            }

            Spacer()

            Button {
                // no-op — calendar action placeholder
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Calendar")
        }
        .frame(height: 56)
        .padding(.horizontal, Spacing.lg)
        .background(Color.white.ignoresSafeArea(edges: .top))
    }
}

// MARK: - TrendAnalysisSection

private struct TrendAnalysisSection: View {

    var vm: ProgressViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible, tappable to collapse
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text("Trend Analysis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black)

                Spacer()

                // Time range pills — only shown when expanded
                if vm.isTrendChartExpanded {
                    HStack(spacing: 4) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    vm.selectedTimeRange == range
                                        ? Color.brandGreen
                                        : Color(white: 0.92)
                                )
                                .foregroundStyle(
                                    vm.selectedTimeRange == range
                                        ? Color.black
                                        : Color(white: 0.50)
                                )
                                .clipShape(Capsule())
                                .onTapGesture {
                                    vm.selectedTimeRange = range
                                }
                                .accessibilityLabel("\(range.rawValue) time range")
                                .accessibilityAddTraits(
                                    vm.selectedTimeRange == range ? [.isSelected] : []
                                )
                        }
                    }
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(white: 0.55))
                    .rotationEffect(.degrees(vm.isTrendChartExpanded ? 0 : -90))
                    .animation(.spring(response: 0.3), value: vm.isTrendChartExpanded)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    vm.isTrendChartExpanded.toggle()
                }
            }
            .accessibilityLabel(
                vm.isTrendChartExpanded ? "Collapse Trend Analysis" : "Expand Trend Analysis"
            )
            .accessibilityAddTraits(.isButton)

            // Collapsible content
            if vm.isTrendChartExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Stats row
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Avg. Weekly Loss")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(white: 0.55))

                            Text(String(format: "%.1f %%", vm.avgWeeklyChange))
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(Color.black)
                                .accessibilityLabel(
                                    String(format: "Average weekly loss %.1f percent", vm.avgWeeklyChange)
                                )
                        }

                        Spacer()

                        // Trend label pill
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                            Text(vm.trendLabel)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.brandGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.brandGreen.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("Trend: \(vm.trendLabel)")
                    }
                    .padding(.horizontal, Spacing.md)

                    // Line chart
                    WeightLineChart(data: vm.weightData)
                        .frame(height: 160)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.bottom, Spacing.md)
                        .accessibilityLabel("Weight trend line chart")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.isTrendChartExpanded)
    }
}

// MARK: - WeightLineChart

private struct WeightLineChart: View {

    let data: [WeightDataPoint]

    var body: some View {
        Chart {
            // Area fill under the line
            ForEach(data) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weightLbs)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.brandGreen.opacity(0.25),
                            Color.brandGreen.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Main trend line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weightLbs)
                )
                .foregroundStyle(Color.brandGreen)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            // Tooltip annotation on the most recent data point
            if let last = data.last {
                PointMark(
                    x: .value("Date", last.date),
                    y: .value("Weight", last.weightLbs)
                )
                .foregroundStyle(Color.brandGreen)
                .annotation(position: .top) {
                    Text(String(format: "%.1f lbs", last.weightLbs))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisValueLabel(
                    format: .dateTime.month(.abbreviated).day(),
                    centered: true
                )
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.55))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                    .foregroundStyle(Color(white: 0.88))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color(white: 0.55))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
    }
}

// MARK: - RadarChartSection

private struct RadarChartSection: View {

    var vm: ProgressViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible, tappable to collapse
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text("Strength Radar")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black)

                Spacer()

                // Legend — only shown when expanded
                if vm.isRadarChartExpanded {
                    HStack(spacing: 12) {
                        LegendDot(color: Color.brandGreen.opacity(0.35), label: "Week 1")
                        LegendDot(color: Color.brandGreen, label: "Week 12")
                    }
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(white: 0.55))
                    .rotationEffect(.degrees(vm.isRadarChartExpanded ? 0 : -90))
                    .animation(.spring(response: 0.3), value: vm.isRadarChartExpanded)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    vm.isRadarChartExpanded.toggle()
                }
            }
            .accessibilityLabel(
                vm.isRadarChartExpanded ? "Collapse Strength Radar" : "Expand Strength Radar"
            )
            .accessibilityAddTraits(.isButton)

            // Collapsible content
            if vm.isRadarChartExpanded {
                VStack(spacing: Spacing.md) {
                    RadarChartView(
                        lifts: vm.lifts,
                        order: vm.radarOrder,
                        selectedLift: Binding(
                            get: { vm.selectedRadarLift },
                            set: { vm.selectedRadarLift = $0 }
                        )
                    )
                    .frame(height: 280)
                    .padding(.horizontal, Spacing.md)
                    .accessibilityLabel("Strength radar chart showing 8 lifts")

                    // Tooltip — shown when a lift dot is tapped
                    if let liftName = vm.selectedRadarLift,
                       let lift = vm.lifts.first(where: { $0.name == liftName }) {
                        HStack {
                            Spacer()
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lift.name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(white: 0.7))

                                HStack(spacing: 4) {
                                    Text(lift.currentWeight)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.white)

                                    Text(lift.changeLabel)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.brandGreen)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(white: 0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(
                                "\(lift.name): \(lift.currentWeight), \(lift.changeLabel)"
                            )
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.isRadarChartExpanded)
    }
}

// MARK: - RadarChartView

struct RadarChartView: View {

    let lifts: [LiftMetric]
    let order: [String]
    @Binding var selectedLift: String?

    // MARK: - Geometry helpers (struct methods avoid local-func inference bug)

    private func radarPoint(index: Int, fraction: Double,
                            center: CGPoint, radius: CGFloat) -> CGPoint {
        let count = order.count
        let angleStep = (2 * Double.pi) / Double(count)
        let angle = (-Double.pi / 2) + Double(index) * angleStep
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius * CGFloat(fraction),
            y: center.y + CGFloat(sin(angle)) * radius * CGFloat(fraction)
        )
    }

    private func shortLabel(_ name: String) -> String {
        switch name {
        case "BENCH PRESS": return "BENCH"
        case "DEADLIFT":    return "DL"
        case "PULL-UPS":    return "PULL"
        case "LEG PRESS":   return "LEG"
        default:            return name
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let center      = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius      = min(geo.size.width, geo.size.height) * 0.38
            let labelRadius = radius + 26
            let count       = order.count

            ZStack {
                // Background grid — 5 concentric polygons + axis spokes
                Canvas { ctx, size in
                    for level in 1...5 {
                        let frac = Double(level) / 5.0
                        var path = Path()
                        for i in 0..<count {
                            let pt = radarPoint(index: i, fraction: frac,
                                                center: center, radius: radius)
                            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                        }
                        path.closeSubpath()
                        ctx.stroke(path, with: .color(Color(white: 0.88)), lineWidth: 1)
                    }
                    for i in 0..<count {
                        var path = Path()
                        path.move(to: center)
                        path.addLine(to: radarPoint(index: i, fraction: 1.0,
                                                    center: center, radius: radius))
                        ctx.stroke(path, with: .color(Color(white: 0.88)), lineWidth: 1)
                    }
                }

                // Week 1 polygon
                Canvas { ctx, _ in
                    let values = order.compactMap { n in lifts.first { $0.name == n }?.radarValueWeek1 }
                    var path = Path()
                    for (i, val) in values.enumerated() {
                        let pt = radarPoint(index: i, fraction: val,
                                            center: center, radius: radius)
                        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                    }
                    path.closeSubpath()
                    ctx.fill(path, with: .color(Color.brandGreen.opacity(0.18)))
                    ctx.stroke(path, with: .color(Color.brandGreen.opacity(0.40)), lineWidth: 1.5)
                }

                // Week 12 polygon
                Canvas { ctx, _ in
                    let values = order.compactMap { n in lifts.first { $0.name == n }?.radarValue }
                    var path = Path()
                    for (i, val) in values.enumerated() {
                        let pt = radarPoint(index: i, fraction: val,
                                            center: center, radius: radius)
                        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                    }
                    path.closeSubpath()
                    ctx.fill(path, with: .color(Color.brandGreen.opacity(0.30)))
                    ctx.stroke(path, with: .color(Color.brandGreen), lineWidth: 2.5)
                }

                // Vertex dots (visual)
                Canvas { ctx, _ in
                    for (i, name) in order.enumerated() {
                        guard let lift = lifts.first(where: { $0.name == name }) else { continue }
                        let pt = radarPoint(index: i, fraction: lift.radarValue,
                                            center: center, radius: radius)
                        ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 4, y: pt.y - 4,
                                                        width: 8, height: 8)),
                                 with: .color(Color.brandGreen))
                    }
                }

                // Invisible tap targets
                ForEach(Array(order.enumerated()), id: \.offset) { (i, name) in
                    if let lift = lifts.first(where: { $0.name == name }) {
                        let pt = radarPoint(index: i, fraction: lift.radarValue,
                                            center: center, radius: radius)
                        Color.clear
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                            .position(pt)
                            .onTapGesture { selectedLift = (selectedLift == name) ? nil : name }
                            .accessibilityLabel("\(name): \(Int(lift.radarValue * 100))% week 12")
                            .accessibilityAddTraits(.isButton)
                    }
                }

                // Axis labels
                ForEach(Array(order.enumerated()), id: \.offset) { (i, name) in
                    let count2  = order.count
                    let step    = (2 * Double.pi) / Double(count2)
                    let angle   = (-Double.pi / 2) + Double(i) * step
                    let labelPt = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * labelRadius,
                        y: center.y + CGFloat(sin(angle)) * labelRadius
                    )
                    Text(shortLabel(name))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(white: 0.45))
                        .position(labelPt)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { selectedLift = nil }
        }
    }
}

// MARK: - DetailedMetricsSection

private struct DetailedMetricsSection: View {

    var vm: ProgressViewModel

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DETAILED METRICS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(white: 0.55))
                .kerning(0.8)
                .padding(.bottom, Spacing.sm)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(vm.lifts) { lift in
                    LiftMetricCard(lift: lift)
                }
            }
        }
    }
}

// MARK: - LiftMetricCard

private struct LiftMetricCard: View {

    let lift: LiftMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name + trend dot
            HStack {
                Text(lift.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(white: 0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Circle()
                    .fill(trendColor(lift.changeTrend))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }

            // Current value
            Text(lift.currentWeight)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.black)

            // Change label with icon
            HStack(spacing: 4) {
                Image(systemName: trendIcon(lift.changeTrend))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(trendColor(lift.changeTrend))
                    .accessibilityHidden(true)

                Text(lift.changeLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(trendColor(lift.changeTrend))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(trendColor(lift.changeTrend).opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field))
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(lift.name): \(lift.currentWeight), \(lift.changeLabel)"
        )
    }

    // MARK: Helpers

    private func trendColor(_ trend: LiftMetric.Trend) -> Color {
        switch trend {
        case .up:      return Color.brandGreen
        case .pr:      return Color.brandGreen
        case .neutral: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .down:    return Color(red: 1.0, green: 0.23, blue: 0.19)
        }
    }

    private func trendIcon(_ trend: LiftMetric.Trend) -> String {
        switch trend {
        case .up:      return "arrow.up"
        case .pr:      return "trophy.fill"
        case .neutral: return "minus"
        case .down:    return "arrow.down"
        }
    }
}

// MARK: - LegendDot

private struct LegendDot: View {

    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview {
    ProgressView_()
}
