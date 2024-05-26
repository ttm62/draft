import Foundation

extension Network {
    func getSwapMethods(body: Data?, completion: @escaping (Result<RPCResponse<SwapMethod>, HTTPError>) -> Void) {
        guard let urlRequest = SwapMethodRequest().asURLRequestWithBody(body: body) else {
            return
        }
        
        apiFetcher.request(request: urlRequest) { result in
            completion(result)
        }
    }
    
    func getSwapSimulate(body: Data?, completion: @escaping (Result<RPCResponse<SwapSimulate>, HTTPError>) -> Void) {
        guard let urlRequest = SwapSimulateRequest().asURLRequestWithBody(body: body) else {
            return
        }
        
        apiFetcher.request(request: urlRequest) { result in
            completion(result)
        }
    }
}

struct RPCResponse<T: Codable>: Codable {
    let jsonrpc: String?
    let result: T?
    let id: Int?
}

struct SwapMethodRequest: NetworkRequest {
    static var base: String = "https://app.ston.fi"
    static var endpoint: String = "/rpc"
    static var method: HTTPMethod = .POST
    
    typealias Response = [RPCResponse<SwapMethod>]
}

struct SwapSimulateRequest: NetworkRequest {
    static var base: String = "https://app.ston.fi"
    static var endpoint: String = "/rpc"
    static var method: HTTPMethod = .POST
    
    typealias Response = [RPCResponse<SwapSimulate>]
}

struct SwapSimulate: Codable {
    let offerAddress, askAddress, routerAddress, poolAddress: String?
    let offerUnits, askUnits, slippageTolerance, minAskUnits: String?
    let swapRate, priceImpact, feeAddress, feeUnits: String?
    let feePercent: String?

    enum CodingKeys: String, CodingKey {
        case offerAddress = "offer_address"
        case askAddress = "ask_address"
        case routerAddress = "router_address"
        case poolAddress = "pool_address"
        case offerUnits = "offer_units"
        case askUnits = "ask_units"
        case slippageTolerance = "slippage_tolerance"
        case minAskUnits = "min_ask_units"
        case swapRate = "swap_rate"
        case priceImpact = "price_impact"
        case feeAddress = "fee_address"
        case feeUnits = "fee_units"
        case feePercent = "fee_percent"
    }
}

struct SwapMethod: Codable {
    let version: Int?
    let assets: [SwapAsset]?
}

// MARK: - Smaller chunks

struct SwapAsset: Codable {
    let contractAddress, symbol, displayName: String?
    let imageURL: String?
    let decimals, priority: Int?
    let kind: SwapKind?
    let deprecated, community, blacklisted, defaultSymbol: Bool?
    let defaultList: Bool?
    let tags: [SwapTag]?
    let thirdPartyUsdPrice, thirdPartyPriceUsd, dexUsdPrice, dexPriceUsd: String?

    enum CodingKeys: String, CodingKey {
        case contractAddress = "contract_address"
        case symbol
        case displayName = "display_name"
        case imageURL = "image_url"
        case decimals, priority, kind, deprecated, community, blacklisted
        case defaultSymbol = "default_symbol"
        case defaultList = "default_list"
        case tags
        case thirdPartyUsdPrice = "third_party_usd_price"
        case thirdPartyPriceUsd = "third_party_price_usd"
        case dexUsdPrice = "dex_usd_price"
        case dexPriceUsd = "dex_price_usd"
    }
}

extension SwapAsset: Identifiable {
    var id: String {
        return symbol ?? ""
    }
}

enum SwapKind: String, Codable {
    case jetton = "JETTON"
    case ton = "TON"
    case wton = "WTON"
}

enum SwapTag: String, Codable {
    case defaultList = "default_list"
    case defaultSymbol = "default_symbol"
    case deprecated = "deprecated"
    case hidden = "hidden"
    case whitelisted = "whitelisted"
}

