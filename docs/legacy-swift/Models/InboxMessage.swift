import Foundation

// ============================================================
// InboxMessage — app-model voor één bericht in de berichten-inbox.
//
// Komt uit `notifications` (live, zie NotificationService) of wordt in demo-modus
// lokaal aangemaakt. `team_join_request`-berichten zijn actie-baar: de eigenaar
// kan ze goedkeuren/afwijzen.
// ============================================================

struct InboxMessage: Identifiable, Equatable {
    let id: UUID
    let kind: Kind
    let title: String
    let body: String?
    let teamId: UUID?
    let requestId: UUID?
    /// Afzender van een persoonlijk bericht (elderly_message) — nodig om het
    /// bijbehorende gesprek te openen. nil bij systeemmeldingen.
    var senderId: UUID? = nil
    var senderName: String? = nil
    /// Bijbehorend hulpverzoek (bij new_task_nearby / neighborhood_needs_you /
    /// help_reminder) — zodat tikken direct dat verzoek opent om aan te nemen.
    var taskId: UUID? = nil
    /// Bijbehorende zorgkring (fase35) — voor team-uitnodigingen, schema-
    /// herinneringen en join-verzoeken.
    var careTeamId: UUID? = nil
    var read: Bool
    let date: Date

    enum Kind: String {
        case teamJoinRequest      = "team_join_request"
        case teamJoinApproved     = "team_join_approved"
        case teamJoinRejected     = "team_join_rejected"
        // Pushsignalen (fase22)
        case newTaskNearby        = "new_task_nearby"
        case neighborhoodNeedsYou = "neighborhood_needs_you"
        case teamMilestone75      = "team_milestone_75"
        case teamMilestone100     = "team_milestone_100"
        case competitionEndingSoon = "competition_ending_soon"
        case competitionResult    = "competition_result"
        case competitionRankChange = "competition_rank_change"
        case helpReminder         = "help_reminder"
        // Persoonlijk bericht van de hulpvrager aan de buddy.
        case elderlyMessage       = "elderly_message"
        // Een hulpvrager heeft deze buddy als vaste buddy gekozen.
        case favoriteBuddy        = "favorite_buddy"
        // Zorgkring-pivot (fase35)
        case teamInvite           = "team_invite"            // "«Naam» zoekt een team"
        case teamInviteReminder   = "team_invite_reminder"   // éénmalige herinnering
        case teamTaskNew          = "team_task_new"          // spontane vraag, team-exclusief
        case slotNew              = "slot_new"               // nieuw schemamoment
        case slotReminder48       = "slot_reminder_48"
        case slotReminder24       = "slot_reminder_24"
        case slotUrgent           = "slot_urgent"            // 30 min vooraf, iedereen mag
        case slotUnfilled         = "slot_unfilled"          // hulpvrager: moment blijft leeg
        case scheduleChanged      = "schedule_changed"
        case careJoinRequest      = "care_join_request"      // buddy wil bij de kring
        case teamReviewReady      = "team_review_ready"      // hulpvrager: beoordeel je team
        case teamChoiceNeeded     = "team_choice_needed"     // hulpvrager: 1-uur-keuze
        case noBuddyFound         = "no_buddy_found"         // excuses + team-advies
        // Teamchat & vervanging (fase36)
        case teamChat             = "team_chat"              // bericht in de teamchat
        case swapRequest          = "swap_request"           // buddy zoekt vervanging
        case swapTaken            = "swap_taken"             // vervanging geregeld
        case shiftReminder        = "shift_reminder"         // 2 uur vooraf: jouw moment komt eraan
        case generic

        init(raw: String) { self = Kind(rawValue: raw) ?? .generic }
    }

    /// Alleen openstaande join-verzoeken hebben Goedkeuren/Afwijzen-knoppen.
    var isActionable: Bool { kind == .teamJoinRequest && requestId != nil }

    /// Waar het tikken op dit bericht naartoe leidt (punt 10). Zo eindigt geen
    /// enkel bericht meer in een dood einde: alles wijst naar een logische pagina.
    var destination: InboxDestination {
        switch kind {
        case .teamJoinRequest, .teamJoinApproved, .teamJoinRejected,
             .teamMilestone75, .teamMilestone100:
            return .teams(teamId: teamId)      // teams-tab, zo mogelijk het betreffende team
        case .competitionEndingSoon, .competitionResult, .competitionRankChange:
            return .competition                // competitie-tab, zo mogelijk de eigen competitie
        case .newTaskNearby, .neighborhoodNeedsYou, .helpReminder, .teamTaskNew:
            return .task(id: taskId)      // het specifieke hulpverzoek (om aan te nemen)
        case .teamInvite, .teamInviteReminder:
            return .teamInvite(careTeamId: careTeamId)
        case .slotNew, .slotReminder48, .slotReminder24, .slotUrgent,
             .scheduleChanged, .careJoinRequest, .teamReviewReady,
             .teamChoiceNeeded, .slotUnfilled,
             .teamChat, .swapRequest, .swapTaken, .shiftReminder:
            return .careTeam(careTeamId: careTeamId)
        case .elderlyMessage:
            return .conversation(partnerId: senderId, partnerName: senderName ?? "Gesprek")
        case .favoriteBuddy, .noBuddyFound, .generic:
            return .map
        }
    }

    var icon: String {
        switch kind {
        case .teamJoinRequest:      return "person.crop.circle.badge.questionmark"
        case .teamJoinApproved:     return "checkmark.seal.fill"
        case .teamJoinRejected:     return "xmark.circle.fill"
        case .newTaskNearby:        return "mappin.and.ellipse"
        case .neighborhoodNeedsYou: return "hand.raised.fill"
        case .teamMilestone75:      return "flame.fill"
        case .teamMilestone100:     return "gift.fill"
        case .competitionEndingSoon: return "hourglass"
        case .competitionResult:    return "trophy.fill"
        case .competitionRankChange: return "chart.line.uptrend.xyaxis"
        case .helpReminder:         return "hand.wave.fill"
        case .elderlyMessage:       return "message.fill"
        case .favoriteBuddy:        return "heart.fill"
        case .teamInvite, .teamInviteReminder: return "person.2.wave.2.fill"
        case .teamTaskNew:          return "bolt.heart.fill"
        case .slotNew:              return "calendar.badge.plus"
        case .slotReminder48, .slotReminder24: return "calendar.badge.exclamationmark"
        case .slotUrgent:           return "bolt.fill"
        case .slotUnfilled:         return "calendar.badge.minus"
        case .scheduleChanged:      return "calendar"
        case .careJoinRequest:      return "person.crop.circle.badge.questionmark"
        case .teamReviewReady:      return "checkmark.seal.fill"
        case .teamChoiceNeeded:     return "questionmark.circle.fill"
        case .noBuddyFound:         return "heart.slash.fill"
        case .teamChat:             return "bubble.left.and.bubble.right.fill"
        case .swapRequest:          return "arrow.triangle.2.circlepath"
        case .swapTaken:            return "checkmark.circle.fill"
        case .shiftReminder:        return "clock.badge.checkmark.fill"
        case .generic:              return "bell.fill"
        }
    }
}
