//
//  ScheduleListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/30/22.
//

import SwiftUI


struct SessionListRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(EventStoreManager.self) private var storeManager
    @ObservedObject var session: Session
    @ObservedObject var group: Group
    @Binding var timerangeFormatter: DateFormatter?

    var body: some View {

        HStack {
            Button(action: {
                group.favorite.toggle()
                saveFavorite()
                storeManager.updateCalendar(for: group, in: session.meeting!)
            }) {
                Image(systemName: group.favorite == true ? "star.fill" : "star")
                    .font(Font.system(size: 24, weight: .bold))
                    .imageScale(.large)
                    .foregroundStyle(Color(hex: areaColors[group.areaKey ?? "ietf"] ?? 0xf6c844))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(group.favorite ? "Remove \(group.acronym ?? "group") from favorites" : "Add \(group.acronym ?? "group") to favorites")
            .accessibilityIdentifier("session.favorite")
            VStack(alignment: .leading) {
                // Minimal spacing so the title runs close to the floor name.
                HStack(spacing: 4) {
                    Text("\(session.name!) (\(group.acronym!))")
                        .bold()
                        .foregroundStyle(.primary)
                    if let loc = session.location {
                        Spacer(minLength: 0)
                        Text("\(loc.level_name!)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .modifier(TrailingLocationWidth())
                    }
                }
                HStack(spacing: 4) {
                    if let formatter = timerangeFormatter {
                        Text("\(formatter.string(from: session.start!))-\(formatter.string(from: session.end!))")
                            .foregroundStyle(.primary)
                            // Keep "0900-1100" on one line in narrow columns; the room name wraps instead.
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    Spacer(minLength: 0)
                    Text(session.location?.name ?? "Unspecified")
                        .foregroundStyle(.secondary)
                        .modifier(TrailingLocationWidth())
                }
            }
        }
    }

    private func saveFavorite() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to save Session group (\(group.acronym!)) favorite \(session.name!)")
            }
        }
    }
}

/// Caps the floor and room names at a fixed maximum width. Short names keep their natural width,
/// so no gap opens next to the title; longer names wrap within the cap, right-aligned.
private struct TrailingLocationWidth: ViewModifier {
    /// The cap, scaled with Dynamic Type so larger text sizes still fit a word per line.
    @ScaledMetric(relativeTo: .body) private var maxWidth: CGFloat = 90

    func body(content: Content) -> some View {
        MaxWidthLayout(maxWidth: maxWidth) {
            content
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Sizes its single child to the child's natural width, but no wider than `maxWidth`
/// (or the space offered); text wraps within that width. Unlike `.frame(maxWidth:)`,
/// it doesn't take the whole maximum when the child is narrower.
private struct MaxWidthLayout: Layout {
    var maxWidth: CGFloat

    private func width(for proposal: ProposedViewSize, child: LayoutSubview) -> CGFloat {
        let ideal = child.sizeThatFits(.unspecified).width
        return min(ideal, maxWidth, proposal.width ?? .infinity)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let width = width(for: proposal, child: child)
        return child.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }
        child.place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing,
                    proposal: ProposedViewSize(width: bounds.width, height: nil))
    }
}

#if DEBUG
#Preview("Session row") {
    @Previewable @State var formatter: DateFormatter? = PreviewData.timerangeFormatter
    List {
        SessionListRowView(session: PreviewData.session, group: PreviewData.group, timerangeFormatter: $formatter)
    }
    .environment(\.managedObjectContext, PreviewData.context)
    .environment(EventStoreManager())
}

#Preview("Session row, narrow column") {
    // Mirrors the schedule list's narrow content column (about 320pt, e.g. iPad portrait).
    @Previewable @State var formatter: DateFormatter? = PreviewData.timerangeFormatter
    List {
        SessionListRowView(session: PreviewData.session, group: PreviewData.group, timerangeFormatter: $formatter)
    }
    .listStyle(.inset)
    .frame(width: 320)
    .environment(\.managedObjectContext, PreviewData.context)
    .environment(EventStoreManager())
}
#endif

