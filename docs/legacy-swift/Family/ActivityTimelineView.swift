import SwiftUI

struct ActivityTimelineView: View {
    @Environment(AppState.self) private var appState

    /// Echte tijdlijn, opgebouwd uit afgeronde bezoeken van de oudere die je
    /// nu beheert. Geen voorbeelddata meer — dit vult zich naarmate er bezoeken
    /// plaatsvinden (en in live-modus uit Supabase).
    private var activityItems: [ActivityItem] {
        appState.taskHistory
            .filter { $0.elderlyName == appState.activeFamilyElderly.firstName }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
            .map { task in
                let buddy = task.assignedBuddyName ?? "een buddy"
                return ActivityItem(
                    id: task.id,
                    date: task.completedAt ?? task.createdAt,
                    icon: task.category.icon,
                    color: BCColors.primary,
                    title: "Bezoek afgerond",
                    detail: "\(buddy) hielp met \(task.category.displayName.lowercased()) bij \(appState.activeFamilyElderly.firstName)."
                )
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Activiteit", subtitle: "Wat is er gebeurd")

            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    Text("Tijdlijn van bezoeken en gebeurtenissen rond \(appState.activeFamilyElderly.firstName).")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                    if activityItems.isEmpty {
                        emptyState
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.xl)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(activityItems) { item in
                                TimelineRow(item: item)
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    }

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    private var emptyState: some View {
        // Lege staat via de merk-component: de pillen-illustratie in plaats
        // van een somber SF-icoon (Brand Guidelines 5.2).
        BCEmptyState(
            icon: "clock.badge.questionmark",
            title: "Nog geen activiteit",
            message: "Zodra er bezoeken plaatsvinden, verschijnen ze hier in de tijdlijn."
        )
    }
}

private struct TimelineRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(item.color.opacity(0.18)).frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(item.color)
                }
                Rectangle()
                    .fill(BCColors.border)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(item.detail)
                    .font(BCTypography.subheadline)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.leading)
                Text(BCFormatters.relativeDateTime.localizedString(for: item.date, relativeTo: Date()))
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.bottom, BCSpacing.md)
        }
    }
}

#Preview {
    ActivityTimelineView().environment(AppState())
}
