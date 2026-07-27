import SwiftUI

// ============================================================
// BCMapPins — kaart-druppels (variant 1A "Ring & hart", fase36)
//
// Twee soorten druppels op de kaart-home van de hulpvrager/familie:
//   • BCTeamMatePin — teamgenoot: prominente navy druppel met Hulpgroene
//     ring, hart-badge en naam-pil. In de druppel de profielfoto van de
//     vrijwilliger (initiaal als terugval).
//   • BCBuddyDropPin — losse buddy: kleinere, zachtere groene druppel,
//     eveneens met profielfoto of initiaal.
//
// Profielfoto's komen uit de privé avatars-bucket via BuddyPhotoCache
// (signed URL's). Geen foto → initiaal, nooit een kapot plaatje.
// ============================================================

/// Prominente druppel voor een teamgenoot (variant 1A).
struct BCTeamMatePin: View {
    let name: String
    /// Profiel-id om de foto op te halen; nil = alleen initiaal (demo).
    var buddyId: UUID? = nil
    var hasAvatar: Bool = false
    var size: CGFloat = 54

    @ObservedObject private var photos = BuddyPhotoCache.shared

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    // Hulpgroene ring om de navy druppel (1A).
                    Circle()
                        .stroke(BCColors.accent, lineWidth: 3.5)
                        .frame(width: size + 9, height: size + 9)
                    Circle()
                        .fill(BCColors.primary)
                        .frame(width: size, height: size)
                        .shadow(color: BCColors.primaryDark.opacity(0.28), radius: 6, x: 0, y: 3)
                    BCPinPhoto(name: name, buddyId: buddyId, hasAvatar: hasAvatar,
                               diameter: size - 6, initialColor: .white,
                               initialFont: BCFont.heading(size * 0.42, .bold))
                }
                // Hart-badge: dit is een vast, vertrouwd gezicht.
                ZStack {
                    Circle().fill(BCColors.accent).frame(width: 20, height: 20)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(BCColors.navy900)
                }
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .offset(x: 4, y: -3)
            }
            BCPinTail(color: BCColors.primary)
                .padding(.top, -2)
            Text(name)
                .font(BCFont.heading(12, .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule(style: .continuous).fill(BCColors.navy900))
        }
        .onAppear {
            if let buddyId, hasAvatar { photos.ensure(buddyId) }
        }
    }
}

/// Kleinere, zachtere druppel voor een losse buddy in de buurt (variant 1A).
struct BCBuddyDropPin: View {
    let name: String
    var buddyId: UUID? = nil
    var hasAvatar: Bool = false
    var size: CGFloat = 34

    @ObservedObject private var photos = BuddyPhotoCache.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(BCColors.accent.opacity(0.35))
                    .frame(width: size, height: size)
                    .overlay(Circle().stroke(BCColors.accent, lineWidth: 1.5))
                    .shadow(color: BCColors.primaryDark.opacity(0.15), radius: 4, x: 0, y: 2)
                BCPinPhoto(name: name, buddyId: buddyId, hasAvatar: hasAvatar,
                           diameter: size - 5, initialColor: BCColors.accentDark,
                           initialFont: BCFont.heading(size * 0.45, .bold))
            }
            BCPinTail(color: BCColors.accent.opacity(0.75), width: 9, height: 6)
        }
        .onAppear {
            if let buddyId, hasAvatar { photos.ensure(buddyId) }
        }
    }
}

/// Foto (signed URL) of initiaal binnen een druppel.
private struct BCPinPhoto: View {
    let name: String
    let buddyId: UUID?
    let hasAvatar: Bool
    let diameter: CGFloat
    let initialColor: Color
    let initialFont: Font

    @ObservedObject private var photos = BuddyPhotoCache.shared

    var body: some View {
        Group {
            if hasAvatar, let buddyId, let url = photos.url(for: buddyId) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        initial
                    }
                }
            } else {
                initial
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }

    private var initial: some View {
        ZStack {
            Color.clear
            Text(String(name.prefix(1)).uppercased())
                .font(initialFont)
                .foregroundStyle(initialColor)
        }
    }
}

/// Het staartje onder een druppel.
struct BCPinTail: View {
    var color: Color
    var width: CGFloat = 12
    var height: CGFloat = 8

    var body: some View {
        BCPinTriangle()
            .fill(color)
            .frame(width: width, height: height)
    }
}

struct BCPinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        Color(hex: 0xEAF0F6).ignoresSafeArea()
        HStack(spacing: 60) {
            BCTeamMatePin(name: "Ria")
            BCBuddyDropPin(name: "Tim")
        }
    }
}
