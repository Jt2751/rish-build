import Foundation
import Combine

struct GridPoint: Hashable {
    let x: Int
    let y: Int
}

enum SnakeDirection: Equatable {
    case up
    case down
    case left
    case right

    var opposite: SnakeDirection {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    var offset: (x: Int, y: Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
}

enum RoundState: Equatable {
    case ready
    case running
    case gameOver
}

@MainActor
final class SnakeGame: ObservableObject {
    let columns = 18
    let rows = 20

    @Published private(set) var snake: [GridPoint] = []
    @Published private(set) var food = GridPoint(x: 0, y: 0)
    @Published private(set) var score = 0
    @Published private(set) var state: RoundState = .ready

    private var direction: SnakeDirection = .right
    private var queuedDirection: SnakeDirection = .right

    init() {
        resetBoard()
    }

    func startNewGame() {
        resetBoard()
        state = .running
    }

    func turn(to newDirection: SnakeDirection) {
        guard state == .running,
              newDirection != direction.opposite,
              newDirection != queuedDirection.opposite else { return }
        queuedDirection = newDirection
    }

    func advance() {
        guard state == .running else { return }

        direction = queuedDirection
        guard let head = snake.first else { return }
        let offset = direction.offset
        let next = GridPoint(x: head.x + offset.x, y: head.y + offset.y)
        let eating = next == food

        guard next.x >= 0, next.x < columns, next.y >= 0, next.y < rows else {
            state = .gameOver
            return
        }

        // The tail moves away on a normal step, so entering its current cell is allowed.
        let occupied = eating ? snake : Array(snake.dropLast())
        guard !occupied.contains(next) else {
            state = .gameOver
            return
        }

        snake.insert(next, at: 0)
        if eating {
            score += 10
            placeFood()
        } else {
            snake.removeLast()
        }
    }

    private func resetBoard() {
        let centerX = columns / 2
        let centerY = rows / 2
        snake = [
            GridPoint(x: centerX, y: centerY),
            GridPoint(x: centerX - 1, y: centerY),
            GridPoint(x: centerX - 2, y: centerY)
        ]
        score = 0
        direction = .right
        queuedDirection = .right
        state = .ready
        placeFood()
    }

    private func placeFood() {
        let freeCells = columns * rows - snake.count
        guard freeCells > 0 else {
            state = .gameOver
            return
        }
        var candidate: GridPoint
        repeat {
            candidate = GridPoint(x: Int.random(in: 0..<columns), y: Int.random(in: 0..<rows))
        } while snake.contains(candidate)
        food = candidate
    }
}
