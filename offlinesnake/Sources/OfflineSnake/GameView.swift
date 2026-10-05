import SwiftUI
import Combine

private enum GameStyle {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.075)
    static let panel = Color(red: 0.075, green: 0.105, blue: 0.125)
    static let mint = Color(red: 0.28, green: 0.91, blue: 0.69)
    static let softMint = Color(red: 0.16, green: 0.64, blue: 0.50)
    static let muted = Color(red: 0.56, green: 0.64, blue: 0.67)
    static let orange = Color(red: 1.0, green: 0.56, blue: 0.31)
}

struct GameView: View {
    @StateObject private var game = SnakeGame()
    @AppStorage("bestScore") private var bestScore = 0
    private let clock = Timer.publish(every: 0.14, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                header
                scoreCards
                board
                    .frame(maxHeight: .infinity)
                    .aspectRatio(18.0 / 20.0, contentMode: .fit)
                controls
                Text("离线单机 · 最高分保存在本机")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(GameStyle.muted.opacity(0.75))
                    .frame(height: 16)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GameStyle.background.ignoresSafeArea())
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .preferredColorScheme(.dark)
        .onReceive(clock) { _ in
            game.advance()
            if game.score > bestScore {
                bestScore = game.score
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GameStyle.mint.opacity(0.13))
                    .frame(width: 44, height: 44)
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(GameStyle.mint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("贪吃蛇")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("慢一点，转弯更稳")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GameStyle.muted)
            }
            Spacer()
            Text("经典模式")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GameStyle.mint)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(GameStyle.mint.opacity(0.10), in: Capsule())
        }
        .frame(height: 48)
    }

    private var scoreCards: some View {
        HStack(spacing: 10) {
            scoreCard(title: "本局得分", value: game.score, icon: "sparkles", accent: GameStyle.mint)
            scoreCard(title: "个人最高", value: bestScore, icon: "trophy.fill", accent: GameStyle.orange)
        }
        .frame(height: 62)
    }

    private func scoreCard(title: String, value: Int, icon: String, accent: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(GameStyle.muted)
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.045), lineWidth: 1)
        }
    }

    private var board: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.055, green: 0.083, blue: 0.095))
            Canvas { context, size in
                let cell = min(size.width / CGFloat(game.columns), size.height / CGFloat(game.rows))
                let boardSize = CGSize(width: cell * CGFloat(game.columns), height: cell * CGFloat(game.rows))
                let origin = CGPoint(x: (size.width - boardSize.width) / 2,
                                     y: (size.height - boardSize.height) / 2)
                let rect = CGRect(origin: origin, size: boardSize)
                context.fill(Path(roundedRect: rect, cornerSize: CGSize(width: 16, height: 16)),
                             with: .color(Color(red: 0.055, green: 0.083, blue: 0.095)))

                var grid = Path()
                for column in 0...game.columns {
                    let x = origin.x + CGFloat(column) * cell
                    grid.move(to: CGPoint(x: x, y: origin.y))
                    grid.addLine(to: CGPoint(x: x, y: origin.y + boardSize.height))
                }
                for row in 0...game.rows {
                    let y = origin.y + CGFloat(row) * cell
                    grid.move(to: CGPoint(x: origin.x, y: y))
                    grid.addLine(to: CGPoint(x: origin.x + boardSize.width, y: y))
                }
                context.stroke(grid, with: .color(.white.opacity(0.035)), lineWidth: 0.6)

                let foodRect = CGRect(x: origin.x + CGFloat(game.food.x) * cell + cell * 0.19,
                                      y: origin.y + CGFloat(game.food.y) * cell + cell * 0.19,
                                      width: cell * 0.62, height: cell * 0.62)
                context.fill(Path(ellipseIn: foodRect), with: .color(GameStyle.orange))
                let shine = CGRect(x: foodRect.minX + cell * 0.13, y: foodRect.minY + cell * 0.12,
                                   width: cell * 0.17, height: cell * 0.17)
                context.fill(Path(ellipseIn: shine), with: .color(.white.opacity(0.8)))

                for (index, segment) in game.snake.enumerated().reversed() {
                    let inset = cell * 0.085
                    let segmentRect = CGRect(x: origin.x + CGFloat(segment.x) * cell + inset,
                                             y: origin.y + CGFloat(segment.y) * cell + inset,
                                             width: cell - inset * 2, height: cell - inset * 2)
                    let color = index == 0 ? GameStyle.mint : GameStyle.softMint
                    context.fill(Path(roundedRect: segmentRect,
                                      cornerSize: CGSize(width: cell * 0.27, height: cell * 0.27)),
                                 with: .color(color))
                    if index == 0 {
                        let eyeSize = max(1.5, cell * 0.095)
                        let eye1 = CGRect(x: segmentRect.midX + cell * 0.12,
                                          y: segmentRect.midY - cell * 0.18,
                                          width: eyeSize, height: eyeSize)
                        let eye2 = CGRect(x: segmentRect.midX + cell * 0.12,
                                          y: segmentRect.midY + cell * 0.08,
                                          width: eyeSize, height: eyeSize)
                        context.fill(Path(ellipseIn: eye1), with: .color(GameStyle.background))
                        context.fill(Path(ellipseIn: eye2), with: .color(GameStyle.background))
                    }
                }
            }
            .padding(10)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 14)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard max(abs(dx), abs(dy)) > 14 else { return }
                        if abs(dx) > abs(dy) {
                            game.turn(to: dx > 0 ? .right : .left)
                        } else {
                            game.turn(to: dy > 0 ? .down : .up)
                        }
                    }
            )

            if game.state != .running {
                Color.black.opacity(0.54)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                VStack(spacing: 12) {
                    Image(systemName: game.state == .ready ? "leaf.fill" : "flag.checkered")
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundStyle(GameStyle.mint)
                    Text(game.state == .ready ? "准备好了吗？" : "本局结束")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(game.state == .ready ? "吃掉橙色果实，挑战更高分" : "得分 \(game.score) · 再试一次吧")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                    Button {
                        game.startNewGame()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: game.state == .ready ? "play.fill" : "arrow.clockwise")
                                .font(.system(size: 12, weight: .bold))
                            Text(game.state == .ready ? "开始游戏" : "再来一局")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(GameStyle.background)
                        .padding(.horizontal, 20)
                        .frame(height: 42)
                        .background(GameStyle.mint, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .multilineTextAlignment(.center)
                .padding(18)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("操控方向")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
                Text("滑动棋盘或点按方向键")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(GameStyle.muted)
                HStack(spacing: 5) {
                    Circle().fill(GameStyle.orange).frame(width: 6, height: 6)
                    Text("碰到边界或自己就结束")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(GameStyle.muted.opacity(0.88))
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: 5) {
                directionButton(.up, symbol: "chevron.up")
                HStack(spacing: 5) {
                    directionButton(.left, symbol: "chevron.left")
                    directionButton(.down, symbol: "chevron.down")
                    directionButton(.right, symbol: "chevron.right")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.045), lineWidth: 1)
        }
    }

    private func directionButton(_ direction: SnakeDirection, symbol: String) -> some View {
        Button {
            game.turn(to: direction)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: 38, height: 34)
                .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityName(for: direction))
    }

    private func accessibilityName(for direction: SnakeDirection) -> String {
        switch direction {
        case .up: return "向上"
        case .down: return "向下"
        case .left: return "向左"
        case .right: return "向右"
        }
    }
}
