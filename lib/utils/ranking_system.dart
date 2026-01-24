import 'package:flutter/material.dart';
import '../models/user_model.dart';

enum RankingLevel { ronin, ashigaru, bushi, hatamoto, daimyo, shogun }

class RankingSystem {
  static RankingLevel calculateRank(
    int completedServices,
    double rating,
    int cancellationCount,
  ) {
    if (completedServices >= 500 && rating >= 4.9 && cancellationCount <= 0)
      return RankingLevel.shogun;
    if (completedServices >= 100 && rating >= 4.8 && cancellationCount <= 2)
      return RankingLevel.daimyo;
    if (completedServices >= 50 && rating >= 4.5 && cancellationCount <= 5)
      return RankingLevel.hatamoto;
    if (completedServices >= 15 && rating >= 4.0 && cancellationCount <= 10)
      return RankingLevel.bushi;
    if (completedServices >= 5 && rating >= 3.0) return RankingLevel.ashigaru;
    return RankingLevel.ronin;
  }

  static double getNextLevelProgress(int completedServices, double rating) {
    // Returns a value between 0.0 and 1.0 representing progress to next level
    // Based primarily on completed services as rating is more volatile
    if (completedServices < 5) {
      return completedServices / 5.0;
    } else if (completedServices < 15) {
      return (completedServices - 5) / (15 - 5);
    } else if (completedServices < 50) {
      return (completedServices - 15) / (50 - 15);
    } else if (completedServices < 100) {
      return (completedServices - 50) / (100 - 50);
    } else if (completedServices < 500) {
      return (completedServices - 100) / (500 - 100);
    } else {
      return 1.0; // Max level
    }
  }

  static RankingLevel getLevelFromString(String rank) {
    return RankingLevel.values.firstWhere(
      (e) => e.toString().split('.').last == rank,
      orElse: () => RankingLevel.ronin,
    );
  }

  static String getRankName(RankingLevel level) {
    switch (level) {
      case RankingLevel.ronin:
        return 'Ronin';
      case RankingLevel.ashigaru:
        return 'Ashigaru';
      case RankingLevel.bushi:
        return 'Bushi';
      case RankingLevel.hatamoto:
        return 'Hatamoto';
      case RankingLevel.daimyo:
        return 'Daimyō';
      case RankingLevel.shogun:
        return 'Shōgun';
    }
  }

  static String getRankTitle(RankingLevel level) {
    switch (level) {
      case RankingLevel.ronin:
        return 'O Guerreiro Errante';
      case RankingLevel.ashigaru:
        return 'O Soldado em Formação';
      case RankingLevel.bushi:
        return 'O Samurai Reconhecido';
      case RankingLevel.hatamoto:
        return 'O Samurai de Elite';
      case RankingLevel.daimyo:
        return 'O Senhor Samurai';
      case RankingLevel.shogun:
        return 'A Lenda Viva';
    }
  }

  static String getRankQuote(RankingLevel level) {
    switch (level) {
      case RankingLevel.ronin:
        return '“Todo samurai começa sua jornada sem um nome.”';
      case RankingLevel.ashigaru:
        return '“Disciplina vem antes da glória.”';
      case RankingLevel.bushi:
        return '“Honra se conquista com ações.”';
      case RankingLevel.hatamoto:
        return '“A lealdade o coloca próximo do senhor.”';
      case RankingLevel.daimyo:
        return '“Lidera pelo exemplo.”';
      case RankingLevel.shogun:
        return '“Seu nome ecoa antes de sua chegada.”';
    }
  }

  static Color getRankColor(RankingLevel level) {
    switch (level) {
      case RankingLevel.ronin:
        return Colors.grey;
      case RankingLevel.ashigaru:
        return Colors.brown;
      case RankingLevel.bushi:
        return Color(0xFF000555);
      case RankingLevel.hatamoto:
        return Colors.amber;
      case RankingLevel.daimyo:
        return Colors.deepPurple;
      case RankingLevel.shogun:
        return Colors.redAccent;
    }
  }

  static IconData getRankIcon(RankingLevel level) {
    switch (level) {
      case RankingLevel.ronin:
        return Icons.person_outline;
      case RankingLevel.ashigaru:
        return Icons.shield_outlined;
      case RankingLevel.bushi:
        return Icons.hardware; // Katana-like
      case RankingLevel.hatamoto:
        return Icons.workspace_premium;
      case RankingLevel.daimyo:
        return Icons.local_police;
      case RankingLevel.shogun:
        return Icons.whatshot;
    }
  }

  static String getRankImage(RankingLevel level) {
    switch (level) {
      case RankingLevel.ronin:
        return 'assets/Ronin.PNG';
      case RankingLevel.ashigaru:
        return 'assets/Ashigaru.PNG';
      case RankingLevel.bushi:
        return 'assets/Bushi.PNG';
      case RankingLevel.hatamoto:
        return 'assets/Hatamoto.PNG';
      case RankingLevel.daimyo:
        return 'assets/Daimyó.PNG';
      case RankingLevel.shogun:
        return 'assets/Shogun.PNG';
    }
  }

  static Map<String, dynamic> getNextLevelRequirement(
    int completedServices,
    double rating,
    int cancellationCount,
  ) {
    if (completedServices < 5 || rating < 3.0) {
      return {
        'next': 'Ashigaru',
        'services': 5,
        'rating': 3.0,
        'cancellations': null,
      };
    } else if (completedServices < 15 ||
        rating < 4.0 ||
        cancellationCount > 10) {
      return {
        'next': 'Bushi',
        'services': 15,
        'rating': 4.0,
        'cancellations': 10,
      };
    } else if (completedServices < 50 ||
        rating < 4.5 ||
        cancellationCount > 5) {
      return {
        'next': 'Hatamoto',
        'services': 50,
        'rating': 4.5,
        'cancellations': 5,
      };
    } else if (completedServices < 100 ||
        rating < 4.8 ||
        cancellationCount > 2) {
      return {
        'next': 'Daimyō',
        'services': 100,
        'rating': 4.8,
        'cancellations': 2,
      };
    } else if (completedServices < 500 ||
        rating < 4.9 ||
        cancellationCount > 0) {
      return {
        'next': 'Shōgun',
        'services': 500,
        'rating': 4.9,
        'cancellations': 0,
      };
    } else {
      return {
        'next': 'Máximo',
        'services': 0,
        'rating': 0.0,
        'cancellations': 0,
      };
    }
  }
}
