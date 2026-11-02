/**
 * [INPUT]: 依赖 Foundation 的 URLSession / JSONDecoder / UserDefaults、Studio 的 CCStudio.worksEndpoint 与 CCLanguage.code
 * [OUTPUT]: 对外提供 CCWork（工作室的一件作品）与 CCStudioWorks（单例：works 列表、refresh）
 * [POS]: Studio 层的作品目录唯一客户端。中台 platform.works → 各 App 的 …/works?lang=（免登录、已排除本 App）→ 这里 → CCWorksGroup。
 *        上次成功的结果整份存本机，冷启动先出缓存；请求失败保留旧值；服务端回空表即真的没有，清空并让该组隐藏
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import Foundation

public struct CCWork: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let tagline: String
    public let iconURL: String
    /// 数字串，交给 StoreKit 应用内商店页
    public let appStoreID: String
    /// 应用内商店页起不来时的兜底
    public let storeURL: String

    enum CodingKeys: String, CodingKey {
        case id, name, tagline
        case iconURL = "icon_url"
        case appStoreID = "app_store_id"
        case storeURL = "store_url"
    }
}

public final class CCStudioWorks: ObservableObject {
    public static let shared = CCStudioWorks()

    @Published public private(set) var works: [CCWork]

    private static let cacheKey = "cc.studio.works"

    /// 中台信封只认 data.items：code 各 App 不同形（胃之书、阿奇、口袋粉丝是数字 200，哒啦啦是字符串 ok），HTTP 200 即成功
    private struct Envelope: Decodable {
        struct Payload: Decodable { let items: [CCWork] }
        let data: Payload?
    }

    private init() {
        works = UserDefaults.standard.data(forKey: Self.cacheKey)
            .flatMap { try? JSONDecoder().decode([CCWork].self, from: $0) } ?? []
    }

    /// 按当前界面语言取目录；失败保留旧值
    public func refresh() async {
        guard let endpoint = CCStudio.worksEndpoint,
              var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else { return }
        components.queryItems = [URLQueryItem(name: "lang", value: CCLanguage.shared.code)]
        guard let url = components.url,
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let items = (try? JSONDecoder().decode(Envelope.self, from: data))?.data?.items
        else { return }
        guard items != works else { return }
        works = items
        if let cache = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(cache, forKey: Self.cacheKey)
        }
    }
}
