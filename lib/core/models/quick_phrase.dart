import 'package:flutter/material.dart';

class QuickPhrase {
  final String english;
  final String nepali;
  final IconData icon;

  const QuickPhrase({
    required this.english,
    required this.nepali,
    required this.icon,
  });
}

const touristQuickPhrases = <QuickPhrase>[
  QuickPhrase(english: 'Hello', nepali: 'नमस्ते', icon: Icons.waving_hand),
  QuickPhrase(
    english: 'What is the price?',
    nepali: 'मूल्य कति हो?',
    icon: Icons.attach_money,
  ),
  QuickPhrase(
    english: 'Can it be cheaper?',
    nepali: 'अलि सस्तो हुन्छ?',
    icon: Icons.monetization_on,
  ),
  QuickPhrase(
    english: 'I want this',
    nepali: 'मलाई यो चाहियो',
    icon: Icons.shopping_bag,
  ),
  QuickPhrase(
    english: 'Please pack it',
    nepali: 'कृपया यो प्याक गर्नुस्',
    icon: Icons.inventory_2,
  ),
  QuickPhrase(
    english: 'Where is the toilet?',
    nepali: 'शौचालय कहाँ छ?',
    icon: Icons.wc,
  ),
  QuickPhrase(
    english: 'Thank you',
    nepali: 'धन्यवाद',
    icon: Icons.favorite_outline,
  ),
];

const traderQuickPhrases = <QuickPhrase>[
  QuickPhrase(english: 'Welcome', nepali: 'स्वागत छ', icon: Icons.waving_hand),
  QuickPhrase(
    english: 'What would you like?',
    nepali: 'के लिन चाहनुहुन्छ?',
    icon: Icons.receipt_long,
  ),
  QuickPhrase(
    english: 'This is the final price',
    nepali: 'यो अन्तिम मूल्य हो',
    icon: Icons.price_check,
  ),
  QuickPhrase(
    english: 'I can give a small discount',
    nepali: 'अलि छुट दिन सक्छु',
    icon: Icons.trending_down,
  ),
  QuickPhrase(
    english: 'Please check the size',
    nepali: 'कृपया साइज हेर्नुस्',
    icon: Icons.straighten,
  ),
  QuickPhrase(
    english: 'Thank you for visiting',
    nepali: 'आउनुभएकोमा धन्यवाद',
    icon: Icons.thumb_up_alt_outlined,
  ),
];
