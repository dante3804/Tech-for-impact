//
//  KakaoService.swift
//  ESPA
//
//  Thin wrapper over Kakao Local REST API for keyword-based address /
//  category search. The REST API key is read from Info.plist's
//  `KAKAO_REST_API_KEY`. The native-app key (used by KakaoMapsSDK)
//  is stored separately as `KAKAO_NATIVE_APP_KEY`.
//  Authorization header format: "KakaoAK <key>".
//

import Foundation

// MARK: - KakaoError

enum KakaoError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case server(status: Int, body: String?)
    case decoding(String)
    case noResults

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Info.plist에 KAKAO_REST_API_KEY가 설정되지 않았습니다."
        case .invalidURL:
            return "잘못된 Kakao API URL입니다."
        case .invalidResponse:
            return "Kakao API 응답을 해석하지 못했습니다."
        case .server(let s, let body):
            return "Kakao API 오류 (\(s)): \(body ?? "")"
        case .decoding(let msg):
            return "Kakao 응답 파싱 실패: \(msg)"
        case .noResults:
            return "검색 결과가 없습니다."
        }
    }
}

// MARK: - Response DTOs

private struct KakaoKeywordSearchResponse: Decodable {
    let documents: [Document]

    struct Document: Decodable {
        let placeName: String
        let addressName: String?
        let roadAddressName: String?
        let x: String        // longitude (string)
        let y: String        // latitude  (string)
        let distance: String?

        enum CodingKeys: String, CodingKey {
            case placeName       = "place_name"
            case addressName     = "address_name"
            case roadAddressName = "road_address_name"
            case x, y, distance
        }
    }
}

// MARK: - KakaoService

final class KakaoService {

    /// Base host for Kakao Local REST API.
    private let baseURL = URL(string: "https://dapi.kakao.com")!

    private let session: URLSession
    private let bundle: Bundle

    init(session: URLSession = .shared, bundle: Bundle = .main) {
        self.session = session
        self.bundle  = bundle
    }

    // MARK: - API key

    /// REST API key read from Info.plist's `KAKAO_REST_API_KEY`.
    /// Used as the bearer in `Authorization: KakaoAK <key>`.
    var apiKey: String? {
        let key = bundle.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String
        guard let key, !key.isEmpty else { return nil }
        return key
    }

    // MARK: - Public API

    /// Keyword search returning lightweight `(name, x, y)` tuples.
    /// `x` is longitude, `y` is latitude (Kakao convention).
    func searchAddress(_ keyword: String) async throws -> [(name: String, x: Double, y: Double)] {
        let docs = try await rawKeywordSearch(query: keyword)
        return docs.compactMap { doc in
            guard let lng = Double(doc.x), let lat = Double(doc.y) else { return nil }
            return (name: doc.placeName, x: lng, y: lat)
        }
    }

    /// Searches for the closest "아파트" (apartment) to `(lat, lng)` and
    /// returns `(distance in km, place name)`.
    /// `radius` is in meters (Kakao max = 20,000).
    func searchNearbyApartments(lat: Double, lng: Double, radius: Int = 20_000) async throws
        -> (distance: Double, name: String)
    {
        let docs = try await rawKeywordSearch(
            query: "아파트",
            x: lng,
            y: lat,
            radius: min(max(radius, 1), 20_000),
            sort: "distance"
        )
        // Pick the entry that reports a parseable `distance` and is closest.
        let candidates: [(distance: Double, name: String)] = docs.compactMap { doc in
            guard let raw = doc.distance, let meters = Double(raw) else { return nil }
            return (distance: meters / 1000.0, name: doc.placeName)
        }
        guard let nearest = candidates.min(by: { $0.distance < $1.distance }) else {
            throw KakaoError.noResults
        }
        return nearest
    }

    // MARK: - Internals

    /// Raw Kakao keyword search. Optional `x`,`y`,`radius`,`sort` enable
    /// distance-based queries.
    private func rawKeywordSearch(
        query: String,
        x: Double? = nil,
        y: Double? = nil,
        radius: Int? = nil,
        sort: String? = nil
    ) async throws -> [KakaoKeywordSearchResponse.Document] {

        guard let apiKey else { throw KakaoError.missingAPIKey }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("/v2/local/search/keyword.json"),
            resolvingAgainstBaseURL: false
        )
        var items: [URLQueryItem] = [URLQueryItem(name: "query", value: query)]
        if let x { items.append(URLQueryItem(name: "x", value: String(x))) }
        if let y { items.append(URLQueryItem(name: "y", value: String(y))) }
        if let radius { items.append(URLQueryItem(name: "radius", value: String(radius))) }
        if let sort { items.append(URLQueryItem(name: "sort", value: sort)) }
        components?.queryItems = items

        guard let url = components?.url else { throw KakaoError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw KakaoError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw KakaoError.server(status: http.statusCode,
                                    body: String(data: data, encoding: .utf8))
        }

        do {
            let decoded = try JSONDecoder().decode(KakaoKeywordSearchResponse.self, from: data)
            return decoded.documents
        } catch {
            throw KakaoError.decoding(error.localizedDescription)
        }
    }
}
