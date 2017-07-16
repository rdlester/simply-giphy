// Model objects corresponding to types from the Giphy API:
// https://developers.giphy.com/docs/#schema-definitions
//
// JSON parsing implemented with Gloss.

import Gloss

// A Giphy User.
struct User: Decodable {

    let avatarURL: URL?
    let bannerURL: URL?
    let profileURL: URL?
    let username: String?
    let displayName: String?
    let twitter: String?

    init?(json: JSON) {
        avatarURL = "avatar_url" <~~ json
        bannerURL = "banner_url" <~~ json
        profileURL = "profile_url" <~~ json
        username = "username" <~~ json
        displayName = "display_name" <~~ json
        twitter = "twitter" <~~ json
    }
}

// An individual Gif Image.
// Not all items are available for all formats - reference the API docs to determine which are available.
struct ImageFormat: Decodable {

    let url: URL?
    let width: Int?
    let height: Int?
    let size: Int?
    let frames: Int?
    let mp4: URL?
    let mp4Size: Int?
    let webp: URL?
    let webpSize: Int?

    init?(json: JSON) {
        url = "url" <~~ json
        width = jsonStringToInt(key: "width", json: json)
        height = jsonStringToInt(key: "height", json: json)
        size = jsonStringToInt(key: "size", json: json)
        frames = jsonStringToInt(key: "frames", json: json)
        mp4 = "mp4" <~~ json
        mp4Size = jsonStringToInt(key: "mp4_size", json: json)
        webp = "webp" <~~ json
        webpSize = jsonStringToInt(key: "webp_size", json: json)
    }
}

// Convert a JSON String value to a Swift Int.
private func jsonStringToInt(key: String, json: JSON) -> Int? {
    let stringVal: String? = key <~~ json
    return stringVal.flatMap { Int($0) }
}

// An array of images in various formats.
struct Images: Decodable {

    let fixedHeight: ImageFormat?
    let fixedHeightStill: ImageFormat?
    let fixedHeightDownsampled: ImageFormat?
    let fixedWidth: ImageFormat?
    let fixedWidthStill: ImageFormat?
    let fixedWidthDownsampled: ImageFormat?
    let fixedHeightSmall: ImageFormat?
    let fixedHeightSmallStill: ImageFormat?
    let fixedWidthSmall: ImageFormat?
    let fixedWidthSmallStill: ImageFormat?
    let downsized: ImageFormat?
    let downsizedStill: ImageFormat?
    let downsizedLarge: ImageFormat?
    let downsizedMedium: ImageFormat?
    let downsizedSmall: ImageFormat?
    let original: ImageFormat?
    let originalStill: ImageFormat?
    let looping: ImageFormat?
    let preview: ImageFormat?
    let previewGif: ImageFormat?

    init?(json: JSON) {
        fixedHeight = "fixed_height" <~~ json
        fixedHeightStill = "fixed_height_still" <~~ json
        fixedHeightDownsampled = "fixed_height_downsampled" <~~ json
        fixedWidth = "fixed_width" <~~ json
        fixedWidthStill = "fixed_width_still" <~~ json
        fixedWidthDownsampled = "fixed_width_downsampled" <~~ json
        fixedHeightSmall = "fixed_height_small" <~~ json
        fixedHeightSmallStill = "fixed_height_small_still" <~~ json
        fixedWidthSmall = "fixed_width_small" <~~ json
        fixedWidthSmallStill = "fixed_width_small_still" <~~ json
        downsized = "downsized" <~~ json
        downsizedStill = "downsized_still" <~~ json
        downsizedLarge = "downsized_large" <~~ json
        downsizedMedium = "downsized_medium" <~~ json
        downsizedSmall = "downsized_small" <~~ json
        original = "original" <~~ json
        originalStill = "original_still" <~~ json
        looping = "looping" <~~ json
        preview = "preview" <~~ json
        previewGif = "preview_gif" <~~ json
    }
}

// Metadata representing the request.
struct Meta: Decodable {

    let msg: String?
    let status: Int?
    let responseId: String?

    init?(json: JSON) {
        msg = "msg" <~~ json
        status = "status" <~~ json
        responseId = "response_id" <~~ json
    }
}

// Paging information for the associated request.
struct Pagination: Decodable {

    let offset: Int?
    let totalCount: Int?
    let count: Int?

    init?(json: JSON) {
        offset = "offset" <~~ json
        totalCount = "total_count" <~~ json
        count = "count" <~~ json
    }
}

// An individual Gif.
struct Gif: Decodable {

    let type: String?
    let id: String? // swiftlint:disable:this identifier_name
    let slug: String?
    let url: URL?
    let bitlyURL: URL?
    let embedURL: URL?
    let source: URL?
    let rating: String?
    let tags: [String]?
    let featuredTags: [String]?
    let user: User?
    let sourceTld: String?
    let sourcePostURL: URL?
    let updateDatetime: Date?
    let createDatetime: Date?
    let importDatetime: Date?
    let trendingDatetime: Date?
    let images: Images?

    init?(json: JSON) {
        type = "type" <~~ json
        id = "id" <~~ json
        slug = "slug" <~~ json
        url = "url" <~~ json
        bitlyURL = "bitly_url" <~~ json
        embedURL = "embed_url" <~~ json
        source = "source" <~~ json
        rating = "rating" <~~ json
        tags = "tags" <~~ json
        featuredTags = "featured_tags" <~~ json
        user = "user" <~~ json
        sourceTld = "source_tld" <~~ json
        sourcePostURL = "source_post_url" <~~ json
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd HH:mm:ss")
        updateDatetime = Decoder.decode(dateForKey: "update_datetime", dateFormatter: dateFormatter)(json)
        createDatetime = Decoder.decode(dateForKey: "create_datetime", dateFormatter: dateFormatter)(json)
        importDatetime = Decoder.decode(dateForKey: "import_datetime", dateFormatter: dateFormatter)(json)
        trendingDatetime = Decoder.decode(dateForKey: "trending_datetime", dateFormatter: dateFormatter)(json)
        images = "images" <~~ json
    }
}

// The Search API response.
struct SearchResponse: Decodable {

    let data: [Gif]?
    let pagination: Pagination?
    let meta: Meta?

    init?(json: JSON) {
        data = "data" <~~ json
        pagination = "pagination" <~~ json
        meta = "meta" <~~ json
    }
}
