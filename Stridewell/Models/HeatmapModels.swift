import Foundation

struct HeatmapResponse: Codable {
    let polylines: [String]
    let run_count: Int
    let bounding_box: BoundingBox?
}

struct BoundingBox: Codable {
    let min_lat: Double
    let max_lat: Double
    let min_lng: Double
    let max_lng: Double
}
