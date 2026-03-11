import CoreLocation

/// Decodes Google-encoded polyline strings (precision 5) into coordinate arrays.
enum PolylineDecoder {

    /// Decodes a Google-encoded polyline string into an array of coordinates.
    /// Returns an empty array if the string is empty or malformed.
    static func decode(_ encoded: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encoded.startIndex
        var lat = 0
        var lng = 0

        while index < encoded.endIndex {
            var result = 0
            var shift = 0
            var b: Int

            // Decode latitude
            repeat {
                guard index < encoded.endIndex else { return coordinates }
                b = Int(encoded[index].asciiValue ?? 0) - 63
                index = encoded.index(after: index)
                result |= (b & 0x1F) << shift
                shift += 5
            } while b >= 0x20

            lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            result = 0
            shift = 0

            // Decode longitude
            repeat {
                guard index < encoded.endIndex else { return coordinates }
                b = Int(encoded[index].asciiValue ?? 0) - 63
                index = encoded.index(after: index)
                result |= (b & 0x1F) << shift
                shift += 5
            } while b >= 0x20

            lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1)

            coordinates.append(CLLocationCoordinate2D(
                latitude: Double(lat) / 1e5,
                longitude: Double(lng) / 1e5
            ))
        }

        return coordinates
    }

    /// Decodes multiple polyline strings, dropping empty or malformed results.
    /// Safe to call from a background Task.
    static func decodeAll(_ polylines: [String]) -> [[CLLocationCoordinate2D]] {
        polylines.compactMap { encoded -> [CLLocationCoordinate2D]? in
            let coords = decode(encoded)
            return coords.isEmpty ? nil : coords
        }
    }
}
