import Foundation

@MainActor
final class PairingModel: ObservableObject {
    @Published var isPaired: Bool
    @Published var generatedCode: String?
    @Published var inputCode = ""
    @Published var errorMessage: String?
    @Published var isBusy = false

    /// 绑定成功后的副作用（例如上报 APNs token），由装配方注入
    var onBound: (@MainActor () async -> Void)?

    private let api: APIClient
    private let credentials: CredentialStore

    init(api: APIClient, credentials: CredentialStore) {
        self.api = api
        self.credentials = credentials
        self.isPaired = credentials.read(.authToken) != nil
    }

    func generateCode() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        struct Empty: Encodable {}
        struct Response: Decodable { let code: String }

        do {
            let data = try await api.post(.pairGenerate, body: Empty())
            generatedCode = try JSONDecoder().decode(Response.self, from: data).code
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func bind() async {
        let code = inputCode.trimmingCharacters(in: .whitespaces)
        guard code.count == 6 else {
            errorMessage = "请输入 6 位配对码"
            return
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        struct Body: Encodable { let code: String }
        struct Response: Decodable {
            let token: String
            let partner: String?
        }

        do {
            let data = try await api.post(.pairBind, body: Body(code: code))
            let response = try JSONDecoder().decode(Response.self, from: data)
            credentials.save(response.token, for: .authToken)
            if let partner = response.partner {
                credentials.save(partner, for: .partnerName)
            }
            isPaired = true
            await onBound?()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func unpair() {
        credentials.delete(.authToken)
        credentials.delete(.partnerName)
        generatedCode = nil
        inputCode = ""
        isPaired = false
    }
}