import 'dart:math';
import '../models/user_model.dart';
import 'ranking_system.dart';

class RatingResult {
  final double newRating;
  final double newRatingCount;
  final double processedGivenRating;

  RatingResult({
    required this.newRating,
    required this.newRatingCount,
    required this.processedGivenRating,
  });
}

class RatingSystem {
  static const double INITIAL_RATING = 3.0;
  static const double MAX_VARIATION = 0.3;

  /// Calculates the new rating for a professional based on the new review.
  ///
  /// [currentRating]: The professional's current rating.
  /// [currentEffectiveCount]: The sum of weights of real ratings so far.
  /// [newRatingValue]: The rating given by the client (1-5).
  /// [rank]: The professional's current rank string (e.g., 'ronin').
  static RatingResult calculateNewRating({
    required double currentRating,
    required double currentEffectiveCount,
    required double newRatingValue,
    required String rank,
  }) {
    // 1. Get Initial Weight based on Rank
    double initialWeight = _getInitialWeight(rank);

    // 2. Process Extreme Ratings (Rule 6)
    // 1 or 5 stars have weight 0.8, others 1.0
    double ratingWeight = _getRatingWeight(newRatingValue);

    // The "value" used in the sum is the rating itself * weight?
    // Formula: (InitRating * InitWeight + Sum(Rating_i * Weight_i)) / (InitWeight + Sum(Weight_i))
    // Wait, typically weighted average is Sum(Value * Weight) / Sum(Weight).
    // The user formula is: (rating_inicial × peso_inicial + soma_avaliacoes_reais) ÷ (peso_inicial + total_avaliacoes_reais)
    // "soma_avaliacoes_reais" usually implies Sum(Value).
    // "total_avaliacoes_reais" usually implies Count.
    // But if we have variable weights, "soma_avaliacoes_reais" should be Sum(Value * Weight) and "total" is Sum(Weight).
    // Let's assume this standard weighted average interpretation.

    // Back-calculate current sum of real ratings (weighted)
    // Current Rating = (InitRating * InitWeight + CurrentSumReal) / (InitWeight + CurrentEffectiveCount)
    // CurrentSumReal = CurrentRating * (InitWeight + CurrentEffectiveCount) - (InitRating * InitWeight)

    double currentTotalWeight = initialWeight + currentEffectiveCount;
    double currentSumRealRatings =
        (currentRating * currentTotalWeight) - (INITIAL_RATING * initialWeight);

    // Handle potential precision errors or negative values from previous bad states
    if (currentSumRealRatings < 0) currentSumRealRatings = 0;

    // Calculate contribution of new rating
    // Note: We use the raw value for the sum, but weighted?
    // If I give 5 stars with 0.8 weight, does it add 5 to the sum or 4?
    // It should add 5 * 0.8 = 4 to the weighted sum.
    double newRatingContribution = newRatingValue * ratingWeight;

    double newSumRealRatings = currentSumRealRatings + newRatingContribution;
    double newEffectiveCount = currentEffectiveCount + ratingWeight;
    double newTotalWeight = initialWeight + newEffectiveCount;

    double calculatedRating =
        (INITIAL_RATING * initialWeight + newSumRealRatings) / newTotalWeight;

    // 4. Anti-Churn / Variation Limit (Rule 5)
    double variation = calculatedRating - currentRating;

    // Truncate variation if it exceeds MAX_VARIATION
    if (variation.abs() > MAX_VARIATION) {
      if (variation > 0) {
        calculatedRating = currentRating + MAX_VARIATION;
      } else {
        calculatedRating = currentRating - MAX_VARIATION;
      }
    }

    // Ensure rating stays within 0-5 bounds
    double finalRating = max(0.0, min(5.0, calculatedRating));

    return RatingResult(
      newRating: finalRating,
      newRatingCount: newEffectiveCount,
      processedGivenRating: newRatingValue, // We store the raw value given
    );
  }

  /// Gets the initial weight based on the professional's rank (Rule 3).
  static double _getInitialWeight(String rankStr) {
    RankingLevel rank = RankingSystem.getLevelFromString(rankStr);

    switch (rank) {
      case RankingLevel.ronin:
        return 7.0;
      case RankingLevel.ashigaru: // Aprendiz
        return 5.0;
      case RankingLevel.bushi: // Samurai
        return 3.0;
      case RankingLevel.hatamoto: // Elite
        return 2.0;
      case RankingLevel.daimyo: // Lendário
      case RankingLevel.shogun:
        return 1.0;
    }
  }

  /// Gets the weight for a specific rating value (Rule 6).
  static double _getRatingWeight(double rating) {
    if (rating <= 1.0 || rating >= 5.0) {
      return 0.8;
    }
    return 1.0;
  }
}
