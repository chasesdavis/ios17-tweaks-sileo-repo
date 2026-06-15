import SwiftUI

private extension Notification.Name {
    static let spotifyReframeConceptClose = Notification.Name("com.chasedavis.spotifyreframe.concept.close")
}

struct SpotifyConceptHomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let jumpBackItems = [
        ConceptTile(title: "The Weeknd", subtitle: "Blinding Lights - 3:20", colors: [.red, .black]),
        ConceptTile(title: "Chill Hits", subtitle: "Mood: Relaxed", colors: [.yellow, .green]),
        ConceptTile(title: "Tame Impala", subtitle: "Let It Happen - 3:45", colors: [.purple, .indigo]),
        ConceptTile(title: "Summer Drive", subtitle: "Mood: Sunny", colors: [.cyan, .orange])
    ]

    private let mixes = [
        ConceptTile(title: "Daily Mix 1", subtitle: "Your daily mix of new music", colors: [.green, .teal]),
        ConceptTile(title: "Daily Mix 2", subtitle: "More of what you love", colors: [.indigo, .purple]),
        ConceptTile(title: "On Repeat", subtitle: "Songs you love right now", colors: [.pink, .purple])
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ConceptBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    ConceptHeader()
                    ConceptSearchBar()
                    ConceptHeroCard()
                    ConceptJumpBackSection(items: jumpBackItems)
                    ConceptMixSection(items: mixes)
                    ConceptAIPicksCard()
                    ConceptLiveMomentsSection()
                }
                .padding(.horizontal, 20)
                .padding(.top, 58)
                .padding(.bottom, 150)
            }

            VStack(spacing: 0) {
                ConceptMiniPlayer()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                ConceptTabBar()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button("Close", systemImage: "xmark") {
                NotificationCenter.default.post(name: .spotifyReframeConceptClose, object: nil)
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
            .padding(.top, 54)
            .padding(.trailing, 18)
            .accessibilityLabel("Close SpotifyReframe concept home")
        }
    }
}

private struct ConceptTile: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let colors: [Color]
}

private struct ConceptBackground: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(colors: [.green.opacity(0.42), .clear], center: .topTrailing, startRadius: 30, endRadius: 360)
            RadialGradient(colors: [.purple.opacity(0.24), .clear], center: .bottomTrailing, startRadius: 20, endRadius: 300)
            LinearGradient(colors: [.clear, .black.opacity(0.62)], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

private struct ConceptHeader: View {
    var body: some View {
        HStack(alignment: .center) {
            Text("Good morning, Chase")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.76)
                .lineLimit(1)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                Text("Spotify AI")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))

                ZStack {
                    Circle().fill(.white.opacity(0.16))
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white.opacity(0.92), .green.opacity(0.65))
                }
                .frame(width: 50, height: 50)
            }
        }
    }
}

private struct ConceptSearchBar: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            Text("What do you want to listen to?")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            Spacer()

            Image(systemName: "mic.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
    }
}

private struct ConceptHeroCard: View {
    var body: some View {
        HStack(spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(LinearGradient(colors: [.orange, .pink, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 204, height: 150)
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: "sunset.fill")
                            .font(.system(size: 58))
                            .foregroundStyle(.white.opacity(0.28))
                            .padding(16)
                    }

                Circle()
                    .fill(.green)
                    .frame(width: 62, height: 62)
                    .shadow(color: .green.opacity(0.56), radius: 18)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    }
                    .offset(x: 16, y: 18)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Good Vibes,\nBetter Days")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A playlist for you, Chase")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))

                Label("Made for you", systemImage: "circle.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .center) {
            ConceptWaveform()
                .frame(height: 112)
                .opacity(0.46)
                .allowsHitTesting(false)
        }
    }
}

private struct ConceptWaveform: View {
    private let heights: [CGFloat] = [0.18, 0.42, 0.76, 0.34, 0.58, 0.92, 0.28, 0.68, 0.38, 0.84, 0.48, 0.22]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<36, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.green.opacity(index % 3 == 0 ? 0.72 : 0.34))
                    .frame(width: 3, height: 84 * heights[index % heights.count])
            }
        }
    }
}

private struct ConceptJumpBackSection: View {
    let items: [ConceptTile]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jump back in")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        ConceptJumpBackTile(item: item)
                    }
                }
            }
        }
    }
}

private struct ConceptJumpBackTile: View {
    let item: ConceptTile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 112, height: 92)
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "music.note")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.52))
                        .padding(12)
                }

            Text(item.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(item.subtitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .lineLimit(1)
        }
        .frame(width: 112, alignment: .leading)
    }
}

private struct ConceptMixSection: View {
    let items: [ConceptTile]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Made for you")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        ConceptMixTile(item: item)
                    }
                }
            }
        }
    }
}

private struct ConceptMixTile: View {
    let item: ConceptTile

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Spacer()
                ZStack {
                    Circle().stroke(.green.opacity(0.88), lineWidth: 4)
                    Circle().trim(from: 0.70, to: 1.0).stroke(.purple, lineWidth: 4)
                }
                .frame(width: 28, height: 28)
            }

            Spacer()

            Text(item.title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(item.subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
        }
        .padding(14)
        .frame(width: 158, height: 94)
        .background(LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 1))
    }
}

private struct ConceptAIPicksCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Daily Picks")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        LinearGradient(colors: [.green.opacity(0.52), .purple.opacity(0.48), .black.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Daily Picks")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Smart picks, just for you")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("AI")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.green, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .padding(18)

                VStack(spacing: 8) {
                    ConceptAIPickPill(title: "Neon Drive", subtitle: "LIVE", color: .pink)
                    ConceptAIPickPill(title: "Chill Vibes Lounge", subtitle: "82% MATCHED", color: .cyan)
                    ConceptAIPickPill(title: "Global Trending", subtitle: "HOT", color: .orange)
                }
                .frame(width: 198)
                .offset(x: 168, y: 42)

                Button("Play AI Daily Picks", systemImage: "play.fill") {}
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.green, in: Circle())
                    .shadow(color: .green.opacity(0.50), radius: 14)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
            }
            .frame(height: 126)
        }
    }
}

private struct ConceptAIPickPill: View {
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color)
                .frame(width: 25, height: 25)
                .overlay(Image(systemName: "waveform").font(.system(size: 12, weight: .bold)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(color)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 38)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

private struct ConceptLiveMomentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Moments")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 14) {
                ConceptMomentTile(title: "Die With A Smile", color: .blue)
                ConceptMomentTile(title: "Sabrina Live", color: .pink)
            }
        }
    }
}

private struct ConceptMomentTile: View {
    let title: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: [color.opacity(0.68), .black], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 92)
            .overlay(alignment: .bottomLeading) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(12)
            }
    }
}

private struct ConceptMiniPlayer: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [.orange, .pink, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text("Levitating")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Dua Lipa")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }

            Spacer()

            Button("Pause", systemImage: "pause.fill") {}
                .labelStyle(.iconOnly)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.green, in: Circle())
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            Capsule()
                .fill(.green)
                .frame(width: 184, height: 3)
                .offset(x: 12, y: -1)
        }
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

private struct ConceptTabBar: View {
    var body: some View {
        HStack {
            ConceptTabItem(title: "Home", systemImage: "house.fill", selected: true)
            Spacer()
            ConceptTabItem(title: "Search", systemImage: "magnifyingglass", selected: false)
            Spacer()
            ConceptTabItem(title: "Your Library", systemImage: "books.vertical", selected: false)
        }
        .padding(.horizontal, 44)
        .padding(.top, 13)
        .padding(.bottom, 28)
        .background(.black.opacity(0.58))
        .background(.ultraThinMaterial)
    }
}

private struct ConceptTabItem: View {
    let title: String
    let systemImage: String
    let selected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(selected ? .green : .white.opacity(0.74))
    }
}

