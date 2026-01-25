import '../models/user_model.dart';

class SamuraiRankHelper {
  static const List<String> ranks = [
    'ronin',
    'ashigaru',
    'bushi',
    'hatamoto',
    'daimyo',
    'shogun',
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

    // Define requirements
    // Ronin: 0
    // Ashigaru: 5
    // Bushi: 20
    // Hatamoto: 50
    // Daimyo: 100
    // Shogun: 200

    int getServiceRequirement(String rank) {
      switch (rank) {
        case 'ronin':
          return 0;
        case 'ashigaru':
          return 5;
        case 'bushi':
          return 20;
        case 'hatamoto':
          return 50;
        case 'daimyo':
          return 100;
        case 'shogun':
          return 200;
        default:
          return 9999;
      }
    }

    String nextRank = ranks[nextRankIndex];
    int prevReqServices = getServiceRequirement(currentRank);
    int nextReqServices = getServiceRequirement(nextRank);

    int servicesNeededForLevel = nextReqServices - prevReqServices;
    int servicesCompletedInLevel =
        user.completedServicesCount - prevReqServices;

    if (servicesNeededForLevel <= 0) return 1.0;

    double progress = (servicesCompletedInLevel / servicesNeededForLevel).clamp(
      0.0,
      1.0,
    );
    return progress;
  }

  static String getRankLabel(String rank) {
    return rank[0].toUpperCase() + rank.substring(1);
  }
}
