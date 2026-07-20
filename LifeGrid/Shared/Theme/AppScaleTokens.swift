struct AppScaleMetrics: Equatable, Sendable {
    let spacingMultiplier: Double
    let minimumTouchTarget: Double
}

extension AppScale {
    var metrics: AppScaleMetrics {
        switch self {
        case .compact:
            AppScaleMetrics(spacingMultiplier: 0.85, minimumTouchTarget: 44)
        case .balanced:
            AppScaleMetrics(spacingMultiplier: 1.0, minimumTouchTarget: 44)
        case .large:
            AppScaleMetrics(spacingMultiplier: 1.15, minimumTouchTarget: 44)
        }
    }
}
