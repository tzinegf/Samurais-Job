import '../models/user_model.dart';

class SamuraiRankHelper {
  static const List<String> ranks = [
    'ronin',
    'ashigaru',
    'bushi',
    'hatamoto',
    'daimyo',
    'shogun'
  ];

  static String getNextRank(String currentRank) {
    int index = ranks.indexOf(currentRank.toLowerCase());
    if (index != -1 && index < ranks.length - 1) {
      return ranks[index + 1];
    }
    return 'shogun'; // Max rank
  }

  static double getProgress(UserModel user) {
    String currentRank = user.ranking.toLowerCase();
    int nextRankIndex = ranks.indexOf(currentRank) + 1;

    if (nextRankIndex >= ranks.length) return 1.0; // Max level

    // Define requirements for next level
    // Logic: Progress is based on the most difficult missing requirement
    // or an average. Let's use average of met requirements.

    // Requirements for next level:
    // Ashigaru: 5 services, 4.0 rating
    // Bushi: 20 services, 4.5 rating
    // Hatamoto: 50 services, 4.7 rating
    // Daimyo: 100 services, 4.8 rating
    // Shogun: 200 services, 4.9 rating, 0 cancellations

    int servicesReq = 0;
    double ratingReq = 0.0;
    int maxCancel = 9999;

    switch (ranks[nextRankIndex]) {
      case 'ashigaru':
        servicesReq = 5;
        ratingReq = 4.0;
        break;
      case 'bushi':
        servicesReq = 20;
        ratingReq = 4.5;
        break;
      case 'hatamoto':
        servicesReq = 50;
        ratingReq = 4.7;
        maxCancel = 5;
        break;
      case 'daimyo':
        servicesReq = 100;
        ratingReq = 4.8;
        maxCancel = 3;
        break;
      case 'shogun':
        servicesReq = 200;
        ratingReq = 4.9;
        maxCancel = 0;
        break;
    }

    double serviceProgress =
        (user.completedServicesCount / servicesReq).clamp(0.0, 1.0);
    double ratingProgress = (user.rating / ratingReq).clamp(0.0, 1.0);
    
    // Cancellation is a penalty, not progress. If violated, progress halts or drops.
    // For simplicity, we just factor it as a boolean multiplier or similar?
    // Let's keep it simple: Progress = (ServiceProgress + RatingProgress) / 2
    // If cancellation limit exceeded, cap progress at 99%? 
    // Or just ignore cancellation for progress bar and let logic prevent promotion.
    
    // Simple visual progress:
    return (serviceProgress + ratingProgress) / 2;
  }
  
  static String getRankLabel(String rank) {
    return rank[0].toUpperCase() + rank.substring(1);
  }
}
