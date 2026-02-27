// Views/Progress/ProgressView_.swift
// SkinIn-iOS
//
// Progress tab — weight trend line chart, body-area strength radar, and summary metrics.
// Named ProgressView_ to avoid collision with SwiftUI's built-in ProgressView.

import SwiftUI
import Charts
import PhotosUI

// MARK: - ProgressView_

struct ProgressView_: View {

    @State private var vm = ProgressViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ProgressNavBar(totalStake: vm.totalStake)

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

                        PhotoProgressSection(vm: vm)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.lg)

                        // Clear the custom tab bar
                        Spacer(minLength: 80)
                    }
                }
            }
        }
        .task { await vm.fetchProgressData() }
    }
}

// MARK: - ProgressNavBar

private struct ProgressNavBar: View {

    let totalStake: Double

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

            if totalStake > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("$\(Int(totalStake))")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color.brandGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.brandGreen.opacity(0.10))
                .clipShape(Capsule())
                .accessibilityLabel("Stake: $\(Int(totalStake)) protected")
            }
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
                                .onTapGesture { vm.selectedTimeRange = range }
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
            ForEach(data) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weightLbs)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.brandGreen.opacity(0.25),
                            Color.brandGreen.opacity(0.02),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weightLbs)
                )
                .foregroundStyle(Color.brandGreen)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

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
            HStack(alignment: .center, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Body Radar")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.black)

                    if vm.isRadarChartExpanded {
                        Text("grows as you log workouts")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.55))
                            .transition(.opacity)
                    }
                }

                Spacer()

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
                vm.isRadarChartExpanded ? "Collapse Body Radar" : "Expand Body Radar"
            )
            .accessibilityAddTraits(.isButton)

            if vm.isRadarChartExpanded {
                RadarChartView(areas: vm.bodyAreas, order: vm.radarOrder)
                    .frame(height: 280)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
                    .accessibilityLabel("Body area radar chart showing muscle group training this week")
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

    let areas: [BodyAreaStat]
    let order: [String]

    // MARK: Geometry helpers

    private func radarPoint(index: Int, fraction: Double,
                            center: CGPoint, radius: CGFloat) -> CGPoint {
        let count     = order.count
        let angleStep = (2 * Double.pi) / Double(count)
        let angle     = (-Double.pi / 2) + Double(index) * angleStep
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius * CGFloat(fraction),
            y: center.y + CGFloat(sin(angle)) * radius * CGFloat(fraction)
        )
    }

    private func shortLabel(_ name: String) -> String {
        switch name {
        case "SHOULDERS": return "SHLDR"
        default:          return name
        }
    }

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            let center      = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius      = min(geo.size.width, geo.size.height) * 0.38
            let labelRadius = radius + 28
            let count       = order.count

            ZStack {
                // Background grid — 5 concentric polygons + axis spokes
                Canvas { ctx, _ in
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

                // Current week polygon — grows as workouts are logged
                Canvas { ctx, _ in
                    let values = order.compactMap { n in
                        areas.first { $0.name == n }?.radarValue
                    }
                    // Only draw if at least one workout has been logged
                    guard values.contains(where: { $0 > 0 }) else { return }
                    var path = Path()
                    for (i, val) in values.enumerated() {
                        // Minimum visible fraction so the polygon is never invisible
                        let displayVal = val > 0 ? max(val, 0.05) : 0.0
                        let pt = radarPoint(index: i, fraction: displayVal,
                                            center: center, radius: radius)
                        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                    }
                    path.closeSubpath()
                    ctx.fill(path,   with: .color(Color.brandGreen.opacity(0.28)))
                    ctx.stroke(path, with: .color(Color.brandGreen), lineWidth: 2.5)
                }

                // Vertex dots — only where a value > 0
                Canvas { ctx, _ in
                    for (i, name) in order.enumerated() {
                        guard let area = areas.first(where: { $0.name == name }),
                              area.radarValue > 0 else { continue }
                        let displayVal = max(area.radarValue, 0.05)
                        let pt = radarPoint(index: i, fraction: displayVal,
                                            center: center, radius: radius)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)),
                            with: .color(Color.brandGreen)
                        )
                    }
                }

                // Axis labels
                ForEach(Array(order.enumerated()), id: \.offset) { (i, name) in
                    let step    = (2 * Double.pi) / Double(order.count)
                    let angle   = (-Double.pi / 2) + Double(i) * step
                    let labelPt = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * labelRadius,
                        y: center.y + CGFloat(sin(angle)) * labelRadius
                    )
                    let trained = (areas.first { $0.name == name }?.radarValue ?? 0) > 0
                    Text(shortLabel(name))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(trained ? Color.brandGreen : Color(white: 0.45))
                        .position(labelPt)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

// MARK: - DetailedMetricsSection

private struct DetailedMetricsSection: View {

    var vm: ProgressViewModel

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
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
                ForEach(vm.progressStats) { stat in
                    ProgressStatCard(stat: stat)
                }
            }
        }
    }
}

// MARK: - ProgressStatCard

private struct ProgressStatCard: View {

    let stat: ProgressStat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(white: 0.55))

            Text(stat.value)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(Color.black)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(stat.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.55))
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field))
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.label): \(stat.value) \(stat.subtitle)")
    }
}

// MARK: - PhotoProgressSection

private struct PhotoProgressSection: View {

    var vm: ProgressViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var fullScreenPhoto: ProgressPhotoMeta?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(alignment: .center) {
                Text("PHOTO PROGRESS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(white: 0.55))
                    .kerning(0.8)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Upload spinner
                if vm.isUploadingPhoto {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                }

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.brandGreen.opacity(0.10))
                    .clipShape(Capsule())
                }
                .disabled(vm.isUploadingPhoto)
                .accessibilityLabel("Add progress photo")
            }
            .padding(.bottom, Spacing.sm)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Spacing.sm) {
                    if vm.progressPhotos.isEmpty && !vm.isUploadingPhoto {
                        EmptyPhotoCard()
                    }

                    ForEach(vm.progressPhotos) { meta in
                        ProgressPhotoCard(meta: meta)
                            .onTapGesture { fullScreenPhoto = meta }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await vm.deletePhoto(meta.id) }
                                } label: {
                                    Label("Delete Photo", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data  = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await vm.addPhoto(image)
                }
                pickerItem = nil
            }
        }
        .sheet(item: $fullScreenPhoto) { meta in
            PhotoFullScreenView(meta: meta) {
                Task {
                    await vm.deletePhoto(meta.id)
                    fullScreenPhoto = nil
                }
            }
        }
    }
}

// MARK: - EmptyPhotoCard

private struct EmptyPhotoCard: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "camera.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color(white: 0.72))

            Text("Add your\nfirst photo")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(white: 0.55))
                .multilineTextAlignment(.center)
        }
        .frame(width: 110, height: 130)
        .background(Color(white: 0.93))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("No progress photos yet. Tap Add to get started.")
    }
}

// MARK: - ProgressPhotoCard

private struct ProgressPhotoCard: View {

    let meta: ProgressPhotoMeta

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {

            // Thumbnail — loaded from signed Supabase Storage URL
            Group {
                if let urlStr = meta.url, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            photoPlaceholder(icon: "exclamationmark.triangle")
                        default:
                            photoPlaceholder(icon: nil)
                        }
                    }
                } else {
                    photoPlaceholder(icon: "photo")
                }
            }
            .frame(width: 110, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Week \(meta.weekNumber)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.black)
                .lineLimit(1)

            Text(meta.createdAt, format: .dateTime.month(.abbreviated).day().year())
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.55))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress photo, Week \(meta.weekNumber)")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func photoPlaceholder(icon: String?) -> some View {
        Color(white: 0.90)
            .overlay {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(Color(white: 0.65))
                } else {
                    ProgressView().scaleEffect(0.7)
                }
            }
    }
}

// MARK: - PhotoFullScreenView

private struct PhotoFullScreenView: View {

    let meta: ProgressPhotoMeta
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let urlStr = meta.url, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .ignoresSafeArea(edges: .bottom)
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundStyle(Color(white: 0.45))
                        default:
                            ProgressView().tint(.white)
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(white: 0.35))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black.opacity(0.6), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Week \(meta.weekNumber)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(meta.createdAt, format: .dateTime.month().day().year())
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.65))
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { showDeleteAlert = true } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color(red: 1.0, green: 0.23, blue: 0.19))
                    }
                    .accessibilityLabel("Delete photo")
                }
            }
            .alert("Delete Photo?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel)      { }
            } message: {
                Text("This photo will be permanently deleted from your account.")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressView_()
}
