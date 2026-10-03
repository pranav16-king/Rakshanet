import 'dart:math' as math;

import '../../models/location_observation.dart';

/// Exception thrown when multilateration cannot proceed due to insufficient
/// valid, fresh, or spatially distinct anchors.
class InsufficientAnchorsException implements Exception {
  final String message;
  final int availableValidAnchors;

  const InsufficientAnchorsException(this.message, {this.availableValidAnchors = 0});

  @override
  String toString() => 'InsufficientAnchorsException: $message (available: $availableValidAnchors)';
}

/// Diagnostic metadata detailing the multilateration execution pipeline.
class MultilaterationDiagnostics {
  final int receivedAnchorCount;
  final int staleOrInaccurateRejectedCount;
  final int outlierRejectedCount;
  final int participatingAnchorCount;
  final double medianResidual;
  final double rmsResidual;
  final List<double> finalAnchorResiduals;

  const MultilaterationDiagnostics({
    required this.receivedAnchorCount,
    required this.staleOrInaccurateRejectedCount,
    required this.outlierRejectedCount,
    required this.participatingAnchorCount,
    required this.medianResidual,
    required this.rmsResidual,
    required this.finalAnchorResiduals,
  });
}

/// Result containing both the solved EstimatedLocation and diagnostic metrics.
class MultilaterationResult {
  final EstimatedLocation location;
  final MultilaterationDiagnostics diagnostics;

  const MultilaterationResult({
    required this.location,
    required this.diagnostics,
  });
}

/// Robust 2D Weighted Least-Squares (WLS) Multilateration Engine.
///
/// Designed for GPS-denied emergency environments where a trapped user or rescue node
/// obtains distance measurements from surrounding peer mesh anchors with known GPS fixes.
///
/// Pipeline:
/// 1. Stale (> 60s) and inaccurate (> 50m GPS accuracy) anchor pruning.
/// 2. Coordinate conversion from WGS84 (lat/lon) to local metric Cartesian (x, y).
/// 3. Inverse-variance measurement weighting: weight = (1 / distUncertainty) * (1 / gpsAccuracy).
/// 4. Linearization via reference anchor circle subtraction.
/// 5. Weighted pseudo-inverse solving: (A^T W A)^(-1) A^T W b.
/// 6. Residual calculation: |distanceToSolved - measuredDistance|.
/// 7. Outlier rejection: iterative elimination of anchors with residual > 2.5 * median residual.
/// 8. Uncertainty radius derivation from RMS residuals and anchor variance.
/// 9. Metric Cartesian back-conversion to WGS84 (lat/lon).
/// 10. Assembly of EstimatedLocation model.
class LocationEstimationEngine {
  /// Radius of the Earth in meters (WGS84 spherical approximation).
  static const double earthRadiusMeters = 6371000.0;

  /// Maximum acceptable anchor age in milliseconds (default: 60 seconds).
  final int maxAnchorAgeMs;

  /// Maximum acceptable anchor GPS horizontal accuracy in meters (default: 50 meters).
  final double maxAnchorGpsAccuracyMeters;

  /// Outlier residual multiplier relative to median residual (default: 2.5x).
  final double outlierMultiplier;

  /// Minimum residual threshold in meters before outlier rejection triggers (default: 5.0m).
  final double minOutlierResidualThresholdMeters;

  const LocationEstimationEngine({
    this.maxAnchorAgeMs = 60000,
    this.maxAnchorGpsAccuracyMeters = 50.0,
    this.outlierMultiplier = 2.5,
    this.minOutlierResidualThresholdMeters = 5.0,
  });

  /// Estimates device location from peer anchors.
  ///
  /// Returns `null` if fewer than 3 valid anchors remain after filtering.
  EstimatedLocation? estimateLocation(
    List<LocationAnchor> anchors, {
    int? referenceTimeMs,
  }) {
    try {
      final result = estimateLocationWithDiagnostics(
        anchors,
        referenceTimeMs: referenceTimeMs,
      );
      return result.location;
    } on InsufficientAnchorsException {
      return null;
    }
  }

  /// Solves multilateration and returns both the EstimatedLocation and
  /// detailed diagnostic telemetry.
  ///
  /// Throws [InsufficientAnchorsException] if fewer than 3 valid anchors are available.
  MultilaterationResult estimateLocationWithDiagnostics(
    List<LocationAnchor> anchors, {
    int? referenceTimeMs,
  }) {
    final now = referenceTimeMs ?? DateTime.now().millisecondsSinceEpoch;

    // Step 1: Collect measurements and reject stale / inaccurate anchors
    final validAnchors = anchors.where((anchor) {
      if (anchor.isStale(maxAgeMs: maxAnchorAgeMs, currentTimeMs: now)) {
        return false;
      }
      if (anchor.anchorGpsAccuracy > maxAnchorGpsAccuracyMeters || anchor.anchorGpsAccuracy <= 0) {
        return false;
      }
      if (anchor.estimatedDistance <= 0 || anchor.distanceUncertainty <= 0) {
        return false;
      }
      if (anchor.latitude.isNaN || anchor.longitude.isNaN) {
        return false;
      }
      return true;
    }).toList();

    final staleOrInaccurateRejectedCount = anchors.length - validAnchors.length;

    if (validAnchors.length < 3) {
      throw InsufficientAnchorsException(
        'At least 3 valid, fresh anchors are required for 2D multilateration. '
        'Found ${validAnchors.length} valid anchors out of ${anchors.length} provided.',
        availableValidAnchors: validAnchors.length,
      );
    }

    // Sort valid anchors by composite weight descending so the origin anchor
    // is the highest-confidence, most accurate node.
    validAnchors.sort((a, b) => b.weight.compareTo(a.weight));

    // Iterative Outlier Rejection Loop (Steps 2 through 7)
    List<LocationAnchor> activeAnchors = List.of(validAnchors);
    int outlierRejectedCount = 0;
    _SolveResult? currentSolve;

    while (activeAnchors.length >= 3) {
      currentSolve = _solveMultilateration(activeAnchors);

      // Check if we have enough anchors for outlier rejection (> 3 anchors)
      if (activeAnchors.length <= 3) {
        break;
      }

      final residuals = currentSolve.residuals;
      final medianRes = _calculateMedian(residuals);

      // Find worst residual
      int maxResidualIndex = 0;
      double maxResidual = residuals[0];
      for (int i = 1; i < residuals.length; i++) {
        if (residuals[i] > maxResidual) {
          maxResidual = residuals[i];
          maxResidualIndex = i;
        }
      }

      // Outlier condition: residual > 2.5 * median residual AND > min threshold
      final outlierThreshold = math.max(
        medianRes * outlierMultiplier,
        minOutlierResidualThresholdMeters,
      );

      if (maxResidual > outlierThreshold) {
        // Reject the outlier anchor and re-solve
        activeAnchors.removeAt(maxResidualIndex);
        outlierRejectedCount++;
      } else {
        // No outlier detected; model converged
        break;
      }
    }

    if (currentSolve == null || activeAnchors.length < 3) {
      throw InsufficientAnchorsException(
        'Multilateration failed to converge with at least 3 valid anchors.',
        availableValidAnchors: activeAnchors.length,
      );
    }

    // Step 8: Compute final uncertainty radius from RMS residual error & anchor weights
    final residuals = currentSolve.residuals;
    final medianResidual = _calculateMedian(residuals);
    final rmsResidual = _calculateRms(residuals);

    // Compute effective anchor measurement uncertainty
    double sumWeights = 0.0;
    double weightedDistUncertainty = 0.0;
    double weightedGpsAccuracy = 0.0;

    for (final anchor in activeAnchors) {
      final w = anchor.weight;
      sumWeights += w;
      weightedDistUncertainty += w * anchor.distanceUncertainty;
      weightedGpsAccuracy += w * anchor.anchorGpsAccuracy;
    }

    final avgDistUncertainty = sumWeights > 0 ? (weightedDistUncertainty / sumWeights) : 25.0;
    final avgGpsAccuracy = sumWeights > 0 ? (weightedGpsAccuracy / sumWeights) : 10.0;

    // The uncertainty radius accounts for geometric residual fit error,
    // propagation distance noise, and anchor GPS uncertainty.
    final uncertaintyRadiusMeters = math.max(
      rmsResidual,
      math.sqrt(math.pow(avgDistUncertainty * 0.5, 2) + math.pow(avgGpsAccuracy, 2)),
    );

    // Step 9: Convert solved (x, y) back to WGS84 (latitude, longitude)
    final originAnchor = activeAnchors[0];
    final solvedCoords = _cartesianToLatLon(
      x: currentSolve.x,
      y: currentSolve.y,
      originLat: originAnchor.latitude,
      originLon: originAnchor.longitude,
    );

    // Confidence rating
    final confidenceRating = _determineConfidence(
      uncertaintyMeters: uncertaintyRadiusMeters,
      rmsResidual: rmsResidual,
      anchorCount: activeAnchors.length,
      hasWifiRtt: activeAnchors.any((a) => a.source == LocationSource.wifiRtt),
    );

    // Step 10: Assemble EstimatedLocation
    final estimatedLocation = EstimatedLocation(
      latitude: solvedCoords.latitude,
      longitude: solvedCoords.longitude,
      uncertaintyRadiusMeters: uncertaintyRadiusMeters,
      anchorCount: activeAnchors.length,
      residualError: rmsResidual,
      confidenceRating: confidenceRating,
      isExactGps: false,
      timestamp: now,
    );

    final diagnostics = MultilaterationDiagnostics(
      receivedAnchorCount: anchors.length,
      staleOrInaccurateRejectedCount: staleOrInaccurateRejectedCount,
      outlierRejectedCount: outlierRejectedCount,
      participatingAnchorCount: activeAnchors.length,
      medianResidual: medianResidual,
      rmsResidual: rmsResidual,
      finalAnchorResiduals: residuals,
    );

    return MultilaterationResult(
      location: estimatedLocation,
      diagnostics: diagnostics,
    );
  }

  /// Solves the 2D linearized Weighted Least Squares system for given anchors.
  _SolveResult _solveMultilateration(List<LocationAnchor> anchors) {
    final origin = anchors[0];
    final n = anchors.length;
    final m = n - 1; // number of linear equations

    // Step 2: Coordinate transformation to local metric Cartesian centered at origin
    final cartesianPoints = <_CartesianPoint>[];
    for (int i = 0; i < n; i++) {
      final pt = _latLonToCartesian(
        lat: anchors[i].latitude,
        lon: anchors[i].longitude,
        originLat: origin.latitude,
        originLon: origin.longitude,
      );
      cartesianPoints.add(pt);
    }

    // Step 3: Compute measurement weights for each anchor
    // weight = (1 / distanceUncertainty) * (1 / anchorGpsAccuracy)
    final anchorWeights = anchors.map((a) => a.weight).toList();
    final originWeight = anchorWeights[0];

    // Step 4: Formulate linear multilateration equations:
    // Subtract reference origin anchor equation:
    // 2 * xi * x + 2 * yi * y = xi^2 + yi^2 - di^2 + d0^2
    // A is m x 2, b is m x 1
    final aMatrix = List.generate(m, (_) => [0.0, 0.0]);
    final bVector = List<double>.filled(m, 0.0);
    final eqWeights = List<double>.filled(m, 0.0);

    final d0 = anchors[0].estimatedDistance;
    final d0Sq = d0 * d0;

    for (int k = 0; k < m; k++) {
      final i = k + 1;
      final xi = cartesianPoints[i].x;
      final yi = cartesianPoints[i].y;
      final di = anchors[i].estimatedDistance;

      aMatrix[k][0] = 2.0 * xi;
      aMatrix[k][1] = 2.0 * yi;
      bVector[k] = (xi * xi) + (yi * yi) - (di * di) + d0Sq;

      // Equation weight combining anchor i and reference anchor 0
      final wi = anchorWeights[i];
      eqWeights[k] = (2.0 * wi * originWeight) / (wi + originWeight);
    }

    // Step 5: Solve via weighted normal equations:
    // (A^T W A) p = A^T W b
    // M = A^T W A is 2x2:
    double m00 = 0.0;
    double m01 = 0.0;
    double m11 = 0.0;

    double v0 = 0.0;
    double v1 = 0.0;

    for (int k = 0; k < m; k++) {
      final a0 = aMatrix[k][0];
      final a1 = aMatrix[k][1];
      final w = eqWeights[k];
      final bk = bVector[k];

      m00 += a0 * w * a0;
      m01 += a0 * w * a1;
      m11 += a1 * w * a1;

      v0 += a0 * w * bk;
      v1 += a1 * w * bk;
    }

    final m10 = m01;

    // Determinant of 2x2 matrix
    double det = (m00 * m11) - (m01 * m10);

    // Tikhonov Regularization for collinear or near-singular matrices
    if (det.abs() < 1e-7) {
      final trace = m00 + m11;
      final damping = math.max(1e-4 * trace, 1e-4);
      m00 += damping;
      m11 += damping;
      det = (m00 * m11) - (m01 * m10);
    }

    if (det.abs() < 1e-12) {
      throw const InsufficientAnchorsException(
        'Collinear or degenerate anchor geometry cannot yield 2D position fix.',
      );
    }

    // Invert 2x2 matrix: M^(-1) * v to obtain initial linear position
    final solvedX = ((m11 * v0) - (m01 * v1)) / det;
    final solvedY = ((-m10 * v0) + (m00 * v1)) / det;

    // Anchor centroid seed (protects against high-leverage corrupted outliers)
    double centroidX = 0.0;
    double centroidY = 0.0;
    for (int i = 0; i < n; i++) {
      centroidX += cartesianPoints[i].x;
      centroidY += cartesianPoints[i].y;
    }
    centroidX /= n;
    centroidY /= n;

    // Evaluate median residual of linear solve vs centroid
    final medianLinear = _calculateMedian(
      List.generate(n, (j) {
        final dist = math.sqrt(
          math.pow(solvedX - cartesianPoints[j].x, 2) +
              math.pow(solvedY - cartesianPoints[j].y, 2),
        );
        return (dist - anchors[j].estimatedDistance).abs();
      }),
    );
    final medianCentroid = _calculateMedian(
      List.generate(n, (j) {
        final dist = math.sqrt(
          math.pow(centroidX - cartesianPoints[j].x, 2) +
              math.pow(centroidY - cartesianPoints[j].y, 2),
        );
        return (dist - anchors[j].estimatedDistance).abs();
      }),
    );

    // Pick seed with lower median residual
    var currentX = medianCentroid < medianLinear ? centroidX : solvedX;
    var currentY = medianCentroid < medianLinear ? centroidY : solvedY;

    for (int iter = 0; iter < 8; iter++) {
      double j00 = 0.0;
      double j01 = 0.0;
      double j11 = 0.0;
      double g0 = 0.0;
      double g1 = 0.0;

      for (int i = 0; i < n; i++) {
        final xi = cartesianPoints[i].x;
        final yi = cartesianPoints[i].y;
        final dx = currentX - xi;
        final dy = currentY - yi;
        final dist = math.sqrt(dx * dx + dy * dy);
        final safeDist = dist > 1e-4 ? dist : 1e-4;

        final ri = dist - anchors[i].estimatedDistance;
        final ux = dx / safeDist;
        final uy = dy / safeDist;

        // Huber M-estimator downweighting for large residuals:
        // Downweights leverage errors (|ri| > 10m) so outlier cannot pull inliers away.
        final huberWeight = 1.0 / math.max(1.0, ri.abs() / 10.0);
        final wi = anchorWeights[i] * huberWeight;

        j00 += ux * wi * ux;
        j01 += ux * wi * uy;
        j11 += uy * wi * uy;

        g0 += ux * wi * ri;
        g1 += uy * wi * ri;
      }

      final jDet = (j00 * j11) - (j01 * j01);
      if (jDet.abs() < 1e-9) break;

      final deltaX = ((j11 * g0) - (j01 * g1)) / jDet;
      final deltaY = ((-j01 * g0) + (j00 * g1)) / jDet;

      currentX -= deltaX;
      currentY -= deltaY;

      if (deltaX.abs() < 1e-4 && deltaY.abs() < 1e-4) break;
    }

    // Step 6: Calculate residual errors for each anchor:
    // residual = |distanceToSolved - measuredDistance|
    final residuals = <double>[];
    for (int j = 0; j < n; j++) {
      final xj = cartesianPoints[j].x;
      final yj = cartesianPoints[j].y;
      final distToSolved = math.sqrt(
        math.pow(currentX - xj, 2) + math.pow(currentY - yj, 2),
      );
      final residual = (distToSolved - anchors[j].estimatedDistance).abs();
      residuals.add(residual);
    }

    return _SolveResult(
      x: currentX,
      y: currentY,
      residuals: residuals,
    );
  }

  /// Converts spherical (lat, lon) degrees to local Cartesian (x, y) meters
  /// centered at (originLat, originLon).
  static _CartesianPoint _latLonToCartesian({
    required double lat,
    required double lon,
    required double originLat,
    required double originLon,
  }) {
    const degToRad = math.pi / 180.0;
    final originLatRad = originLat * degToRad;

    final x = (lon - originLon) * degToRad * earthRadiusMeters * math.cos(originLatRad);
    final y = (lat - originLat) * degToRad * earthRadiusMeters;

    return _CartesianPoint(x, y);
  }

  /// Converts local Cartesian (x, y) meters back to spherical (lat, lon) degrees.
  static _LatLonPoint _cartesianToLatLon({
    required double x,
    required double y,
    required double originLat,
    required double originLon,
  }) {
    const radToDeg = 180.0 / math.pi;
    const degToRad = math.pi / 180.0;
    final originLatRad = originLat * degToRad;

    final cosOrigin = math.cos(originLatRad);
    final safeCos = cosOrigin.abs() > 1e-9 ? cosOrigin : 1.0;

    final lat = originLat + (y / earthRadiusMeters) * radToDeg;
    final lon = originLon + (x / (earthRadiusMeters * safeCos)) * radToDeg;

    return _LatLonPoint(lat, lon);
  }

  /// Computes the median value of a numerical list.
  static double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
  }

  /// Computes the root-mean-square (RMS) of a list.
  static double _calculateRms(List<double> values) {
    if (values.isEmpty) return 0.0;
    double sumSq = 0.0;
    for (final v in values) {
      sumSq += v * v;
    }
    return math.sqrt(sumSq / values.length);
  }

  /// Categorizes solution accuracy into qualitative 'High', 'Medium', or 'Low' confidence.
  static String _determineConfidence({
    required double uncertaintyMeters,
    required double rmsResidual,
    required int anchorCount,
    required bool hasWifiRtt,
  }) {
    if ((hasWifiRtt || uncertaintyMeters <= 20.0) && rmsResidual <= 15.0 && anchorCount >= 4) {
      return 'High';
    } else if (uncertaintyMeters <= 45.0 && rmsResidual <= 30.0) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
}

class _CartesianPoint {
  final double x;
  final double y;
  const _CartesianPoint(this.x, this.y);
}

class _LatLonPoint {
  final double latitude;
  final double longitude;
  const _LatLonPoint(this.latitude, this.longitude);
}

class _SolveResult {
  final double x;
  final double y;
  final List<double> residuals;
  const _SolveResult({
    required this.x,
    required this.y,
    required this.residuals,
  });
}
