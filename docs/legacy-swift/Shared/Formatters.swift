//  Formatters.swift
//  Gedeelde formatters — één bron van waarheid voor identieke datum-/tijdweergave.

import Foundation

enum BCFormatters {
    /// Relatieve tijd in het Nederlands ("3 dagen geleden"), volledige eenheden.
    /// Bundelt drie identieke definities (cliënt-home, familie-tijdlijn, inbox);
    /// de uitvoer is teken-voor-teken gelijk aan de vorige losse formatters.
    static let relativeDateTime: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.unitsStyle = .full
        return f
    }()
}
