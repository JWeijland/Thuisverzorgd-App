//  AppStateLive+EnumMapping.swift
//  Live-laag van AppState — Swift↔Postgres enum-mapping.
//  Puur verplaatst uit AppStateLive.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Enum-mapping tussen Swift en de Postgres-enums
//
// De Swift-rawValues (walkOutdoors, digitalHelp, …) wijken af van de
// snake_case Postgres-enumwaarden (walk_outdoors, digital_help, …). Zonder
// deze mapping zou een insert falen op de CHECK van het enum.

extension TaskCategory {
    var dbValue: String {
        switch self {
        case .companionship: return "companionship"
        case .walkOutdoors:  return "walk_outdoors"
        case .groceries:     return "groceries"
        case .activity:      return "activity"
        case .digitalHelp:   return "digital_help"
        case .socialSupport: return "social_support"
        case .lightCleaning: return "light_cleaning"
        case .appointment:   return "appointment"
        case .other:         return "other"
        }
    }

    init(dbValue: String) {
        switch dbValue {
        case "walk_outdoors":  self = .walkOutdoors
        case "digital_help":   self = .digitalHelp
        case "social_support": self = .socialSupport
        case "light_cleaning": self = .lightCleaning
        default:               self = TaskCategory(rawValue: dbValue) ?? .other
        }
    }
}

extension TaskStatus {
    var dbValue: String {
        switch self {
        case .inProgress: return "in_progress"
        default:          return rawValue
        }
    }

    init(dbValue: String) {
        switch dbValue {
        case "in_progress": self = .inProgress
        default:            self = TaskStatus(rawValue: dbValue) ?? .open
        }
    }
}
