import Foundation

enum TransportError: Error {
    case notPaired
    case unreachable
    case network(Error)
    case serverRejected(String)
}

extension TransportError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notPaired:
            return "尚未配对"
        case .unreachable:
            return "无法连接服务器"
        case .network(let error):
            return "网络错误：\(error.localizedDescription)"
        case .serverRejected(let message):
            return message
        }
    }
}

enum TransportResult: Equatable {
    case deliveredLocally
    case deliveredViaServer
    case failed(String)
}