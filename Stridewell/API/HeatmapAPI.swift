import Foundation

extension APIClient {
    func heatmap() async -> ApiResult<HeatmapResponse> {
        await get(path: APIEndpoints.runsHeatmap)
    }
}
