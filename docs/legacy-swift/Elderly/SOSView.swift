import SwiftUI

struct SOSView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BCColors.danger.ignoresSafeArea()
            VStack(spacing: BCSpacing.xl) {
                Spacer()

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 72, weight: .heavy))
                    .foregroundStyle(.white)

                Text("SOS-alarm")
                    .font(BCTypography.largeTitle)
                    .foregroundStyle(.white)

                Text("U staat op het punt om hulp te alarmeren.\nUw familie en vaste buddies worden meteen gebeld.")
                    .font(BCTypography.elderlyBody)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.lg)

                Spacer()

                VStack(spacing: BCSpacing.sm) {
                    Button { } label: {
                        HStack {
                            Image(systemName: "phone.fill.arrow.up.right")
                            Text("Bel 112 direct")
                        }
                        .font(BCTypography.elderlyButton)
                        .foregroundStyle(BCColors.danger)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .fill(.white)
                        )
                    }
                    .buttonStyle(.plain)

                    Button { } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Waarschuw familie & buddies")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .stroke(.white, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, BCSpacing.lg)

                Button { dismiss() } label: {
                    Text("Annuleren, geen alarm")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.vertical, BCSpacing.md)
                }
                .buttonStyle(.plain)

                Spacer().frame(height: BCSpacing.lg)
            }
        }
    }
}

#Preview {
    SOSView().environment(AppState())
}
