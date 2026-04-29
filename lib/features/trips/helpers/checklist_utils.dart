import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/models/app_language.dart';
import '../../../core/utils/localization.dart';

class ChecklistTemplateItemSeed {
  const ChecklistTemplateItemSeed({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.order,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int order;
}

class ChecklistTemplateGroupSeed {
  const ChecklistTemplateGroupSeed({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.order,
    required this.items,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int order;
  final List<ChecklistTemplateItemSeed> items;
}

const List<ChecklistTemplateGroupSeed> checklistTemplateGroups = [
  ChecklistTemplateGroupSeed(
    id: 'quick_pick',
    nameAr: 'القائمة السريعة',
    nameEn: 'Quick Pick',
    order: 1,
    items: [
      ChecklistTemplateItemSeed(
        id: 'chairs',
        nameAr: 'كراسي',
        nameEn: 'Chairs',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'mat',
        nameAr: 'فرشة',
        nameEn: 'Mat',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'dates',
        nameAr: 'تمر',
        nameEn: 'Dates',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'coffee_thermos',
        nameAr: 'ترامس قهوة وشاي',
        nameEn: 'Coffee & Tea Thermoses',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'water',
        nameAr: 'ماء',
        nameEn: 'Water',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'hanging_light',
        nameAr: 'إضاءة معلقة',
        nameEn: 'Hanging Light',
        order: 6,
      ),
    ],
  ),
  ChecklistTemplateGroupSeed(
    id: 'camping',
    nameAr: 'معدات التخييم',
    nameEn: 'Camping Setup',
    order: 2,
    items: [
      ChecklistTemplateItemSeed(
        id: 'tent',
        nameAr: 'خيمة',
        nameEn: 'Tent',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'rope_stakes',
        nameAr: 'حبل وأوتاد تثبيت',
        nameEn: 'Rope & Stakes',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'canopy',
        nameAr: 'رواق',
        nameEn: 'Canopy',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'sleeping_mattress',
        nameAr: 'فراش نوم',
        nameEn: 'Sleeping Mattress',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'pillow',
        nameAr: 'وسادة',
        nameEn: 'Pillow',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'foldable_table',
        nameAr: 'طاولة قابلة للطي',
        nameEn: 'Foldable Table',
        order: 6,
      ),
      ChecklistTemplateItemSeed(
        id: 'chairs',
        nameAr: 'كراسي',
        nameEn: 'Chairs',
        order: 7,
      ),
      ChecklistTemplateItemSeed(
        id: 'hanging_light',
        nameAr: 'إضاءة معلقة',
        nameEn: 'Hanging Light',
        order: 8,
      ),
      ChecklistTemplateItemSeed(
        id: 'flashlight',
        nameAr: 'كشاف يدوي',
        nameEn: 'Flashlight',
        order: 9,
      ),
    ],
  ),
  ChecklistTemplateGroupSeed(
    id: 'cooking',
    nameAr: 'معدات الطبخ والشوي',
    nameEn: 'Cooking & BBQ',
    order: 3,
    items: [
      ChecklistTemplateItemSeed(
        id: 'charcoal',
        nameAr: 'فحم',
        nameEn: 'Charcoal',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'grill',
        nameAr: 'منقل فحم',
        nameEn: 'Charcoal Grill',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'firewood',
        nameAr: 'حطب',
        nameEn: 'Firewood',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'fire_starter',
        nameAr: 'مكعبات الاشعال',
        nameEn: 'Fire Starters',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'tongs',
        nameAr: 'ملقط شوي',
        nameEn: 'BBQ Tongs',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'gas_stove',
        nameAr: 'دافور',
        nameEn: 'Gas Stove',
        order: 6,
      ),
      ChecklistTemplateItemSeed(
        id: 'grill_net',
        nameAr: 'شبك شوي',
        nameEn: 'Grill Net',
        order: 7,
      ),
      ChecklistTemplateItemSeed(
        id: 'skewers',
        nameAr: 'عيدان شوي',
        nameEn: 'Skewers',
        order: 8,
      ),
      ChecklistTemplateItemSeed(
        id: 'foil',
        nameAr: 'قصدير',
        nameEn: 'Aluminum Foil',
        order: 9,
      ),
      ChecklistTemplateItemSeed(
        id: 'pressure_cooker',
        nameAr: 'قدر ضغط',
        nameEn: 'Pressure Cooker',
        order: 10,
      ),
      ChecklistTemplateItemSeed(
        id: 'pots',
        nameAr: 'قدور',
        nameEn: 'Cooking Pots',
        order: 11,
      ),
      ChecklistTemplateItemSeed(
        id: 'cooking_spoon',
        nameAr: 'ملعقة طبخ',
        nameEn: 'Cooking Spoon',
        order: 12,
      ),
      ChecklistTemplateItemSeed(
        id: 'knife',
        nameAr: 'سكين',
        nameEn: 'Knife',
        order: 13,
      ),
      ChecklistTemplateItemSeed(
        id: 'steel_plate',
        nameAr: 'صحن ستيل',
        nameEn: 'Steel Plate',
        order: 14,
      ),
      ChecklistTemplateItemSeed(
        id: 'matches',
        nameAr: 'كبريت',
        nameEn: 'Matches',
        order: 15,
      ),
      ChecklistTemplateItemSeed(
        id: 'table_mat',
        nameAr: 'سفرة',
        nameEn: 'Table Mat',
        order: 16,
      ),
      ChecklistTemplateItemSeed(
        id: 'cutting_board',
        nameAr: 'لوحة تقطيع',
        nameEn: 'Cutting Board',
        order: 17,
      ),
      ChecklistTemplateItemSeed(
        id: 'cleaning_liquid',
        nameAr: 'سائل تنظيف',
        nameEn: 'cleaning liquid',
        order: 18,
      ),
    ],
  ),
  ChecklistTemplateGroupSeed(
    id: 'coffee',
    nameAr: 'ركن القهوة والشاي',
    nameEn: 'Coffee & Tea Setup',
    order: 4,
    items: [
      ChecklistTemplateItemSeed(
        id: 'coffee_pot',
        nameAr: 'ابريق قهوة',
        nameEn: 'Coffee Pot',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'tea_pot',
        nameAr: 'ابريق شاي',
        nameEn: 'Tea Pot',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'coffee_thermos',
        nameAr: 'ترمس قهوة',
        nameEn: 'Coffee Thermos',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'tea_thermos',
        nameAr: 'ترمس شاي',
        nameEn: 'Tea Thermos',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'cups',
        nameAr: 'فناجيل',
        nameEn: 'Cups',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'coffee_cardamom',
        nameAr: 'قهوة وهيل',
        nameEn: 'Coffee & Cardamom',
        order: 6,
      ),
      ChecklistTemplateItemSeed(
        id: 'coffee_spices',
        nameAr: 'بهارات قهوة',
        nameEn: 'Coffee Spices',
        order: 7,
      ),
      ChecklistTemplateItemSeed(
        id: 'tea',
        nameAr: 'شاي',
        nameEn: 'Tea',
        order: 8,
      ),
      ChecklistTemplateItemSeed(
        id: 'green_tea',
        nameAr: 'شاي اخضر',
        nameEn: 'Green Tea',
        order: 9,
      ),
      ChecklistTemplateItemSeed(
        id: 'sugar',
        nameAr: 'سكر',
        nameEn: 'Sugar',
        order: 10,
      ),
      ChecklistTemplateItemSeed(
        id: 'sweetener',
        nameAr: 'محلي صناعي',
        nameEn: 'Sweetener',
        order: 11,
      ),
      ChecklistTemplateItemSeed(
        id: 'milk',
        nameAr: 'حليب',
        nameEn: 'Milk',
        order: 12,
      ),
      ChecklistTemplateItemSeed(
        id: 'mint',
        nameAr: 'نعناع',
        nameEn: 'Mint',
        order: 13,
      ),
      ChecklistTemplateItemSeed(
        id: 'basil',
        nameAr: 'حبق',
        nameEn: 'Basil',
        order: 14,
      ),
    ],
  ),
  ChecklistTemplateGroupSeed(
    id: 'serving',
    nameAr: 'أدوات الأكل والتقديم',
    nameEn: 'Serving & Disposable',
    order: 5,
    items: [
      ChecklistTemplateItemSeed(
        id: 'plastic_plates',
        nameAr: 'صحون بلاستيك',
        nameEn: 'Plastic Plates',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'plastic_spoons',
        nameAr: 'ملاعق بلاستيك',
        nameEn: 'Plastic Spoons',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'paper_cups',
        nameAr: 'أكواب ورق',
        nameEn: 'Paper Cups',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'tissues',
        nameAr: 'مناديل',
        nameEn: 'Tissues',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'trash_bags',
        nameAr: 'اكياس قمامة',
        nameEn: 'Trash Bags',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'gloves',
        nameAr: 'قفازات بلاستيك',
        nameEn: 'Plastic Gloves',
        order: 6,
      ),
    ],
  ),
  ChecklistTemplateGroupSeed(
    id: 'food',
    nameAr: 'مكونات الطبخ',
    nameEn: 'Food Ingredients',
    order: 6,
    items: [
      ChecklistTemplateItemSeed(
        id: 'rice',
        nameAr: 'رز',
        nameEn: 'Rice',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'chicken',
        nameAr: 'دجاج',
        nameEn: 'Chicken',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'meat',
        nameAr: 'لحم',
        nameEn: 'Meat',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'spices',
        nameAr: 'بهارات',
        nameEn: 'Spices',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'salt',
        nameAr: 'ملح',
        nameEn: 'Salt',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'tomato_sauce',
        nameAr: 'صلصة طماطم',
        nameEn: 'Tomato Sauce',
        order: 6,
      ),
      ChecklistTemplateItemSeed(
        id: 'mayo',
        nameAr: 'مايونيز',
        nameEn: 'Mayonnaise',
        order: 7,
      ),
      ChecklistTemplateItemSeed(
        id: 'ketchup',
        nameAr: 'كتشب',
        nameEn: 'Ketchup',
        order: 8,
      ),
      ChecklistTemplateItemSeed(
        id: 'tomatoes',
        nameAr: 'طماطم',
        nameEn: 'Tomatoes',
        order: 9,
      ),
      ChecklistTemplateItemSeed(
        id: 'onions',
        nameAr: 'بصل',
        nameEn: 'Onions',
        order: 10,
      ),
      ChecklistTemplateItemSeed(
        id: 'garlic',
        nameAr: 'ثوم',
        nameEn: 'Garlic',
        order: 11,
      ),
      ChecklistTemplateItemSeed(
        id: 'cucumber',
        nameAr: 'خيار',
        nameEn: 'Cucumber',
        order: 12,
      ),
      ChecklistTemplateItemSeed(
        id: 'lemon',
        nameAr: 'ليمون',
        nameEn: 'Lemon',
        order: 13,
      ),
      ChecklistTemplateItemSeed(
        id: 'greens',
        nameAr: 'ورقيات',
        nameEn: 'Leafy Greens',
        order: 14,
      ),
      ChecklistTemplateItemSeed(
        id: 'oil',
        nameAr: 'زيت طبخ',
        nameEn: 'Cooking Oil',
        order: 15,
      ),
      ChecklistTemplateItemSeed(
        id: 'chili',
        nameAr: 'شطة',
        nameEn: 'Chili Sauce',
        order: 16,
      ),
      ChecklistTemplateItemSeed(
        id: 'bread',
        nameAr: 'خبز',
        nameEn: 'Bread',
        order: 17,
      ),
      ChecklistTemplateItemSeed(
        id: 'tahini',
        nameAr: 'طحينة سائلة',
        nameEn: 'Tahini',
        order: 18,
      ),
      ChecklistTemplateItemSeed(
        id: 'dates',
        nameAr: 'تمر',
        nameEn: 'Dates',
        order: 19,
      ),
      ChecklistTemplateItemSeed(
        id: 'cream',
        nameAr: 'قشطة',
        nameEn: 'Cream',
        order: 20,
      ),
      ChecklistTemplateItemSeed(
        id: 'yogurt',
        nameAr: 'زبادي',
        nameEn: 'Yogurt',
        order: 21,
      ),
    ],
  ),
  ChecklistTemplateGroupSeed(
    id: 'snacks',
    nameAr: 'سناكات ومشروبات',
    nameEn: 'Snacks & Drinks',
    order: 7,
    items: [
      ChecklistTemplateItemSeed(
        id: 'water',
        nameAr: 'ماء تحلية',
        nameEn: 'Water',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'soda',
        nameAr: 'مشروب غازي',
        nameEn: 'Soda',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'laban',
        nameAr: 'لبن',
        nameEn: 'Laban',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'juice',
        nameAr: 'عصير فواكه',
        nameEn: 'Juice',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'maamoul',
        nameAr: 'معمول',
        nameEn: 'Maamoul',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'chips',
        nameAr: 'شيبس',
        nameEn: 'Chips',
        order: 6,
      ),
      ChecklistTemplateItemSeed(
        id: 'nuts',
        nameAr: 'مكسرات',
        nameEn: 'Nuts',
        order: 7,
      ),
      ChecklistTemplateItemSeed(
        id: 'ice',
        nameAr: 'ثلج',
        nameEn: 'Ice',
        order: 8,
      ),
    ],
  ),
  ChecklistTemplateGroupSeed(
    id: 'entertainment',
    nameAr: 'الترفيه',
    nameEn: 'Entertainment',
    order: 8,
    items: [
      ChecklistTemplateItemSeed(
        id: 'baloot',
        nameAr: 'ورق بلوت',
        nameEn: 'Baloot Cards',
        order: 1,
      ),
      ChecklistTemplateItemSeed(
        id: 'uno',
        nameAr: 'أونو',
        nameEn: 'Uno',
        order: 2,
      ),
      ChecklistTemplateItemSeed(
        id: 'carrom',
        nameAr: 'كيرم',
        nameEn: 'Carrom',
        order: 3,
      ),
      ChecklistTemplateItemSeed(
        id: 'chess',
        nameAr: 'شطرنج',
        nameEn: 'Chess',
        order: 4,
      ),
      ChecklistTemplateItemSeed(
        id: 'backgammon',
        nameAr: 'طاولة زهر',
        nameEn: 'Backgammon',
        order: 5,
      ),
      ChecklistTemplateItemSeed(
        id: 'domino',
        nameAr: 'ضومنة',
        nameEn: 'Domino',
        order: 6,
      ),
      ChecklistTemplateItemSeed(
        id: 'football',
        nameAr: 'كرة قدم',
        nameEn: 'Football',
        order: 7,
      ),
      ChecklistTemplateItemSeed(
        id: 'volleyball',
        nameAr: 'كرة طائرة',
        nameEn: 'Volleyball',
        order: 8,
      ),
      ChecklistTemplateItemSeed(
        id: 'goggles',
        nameAr: 'نظارات سباحة',
        nameEn: 'Swimming Goggles',
        order: 9,
      ),
      ChecklistTemplateItemSeed(
        id: 'swim_vests',
        nameAr: 'سترات سباحة',
        nameEn: 'Swim Vests',
        order: 10,
      ),
    ],
  ),
];

String checklistDisplayName({
  required Tr tr,
  required Map<String, dynamic> data,
  required String arKey,
  required String enKey,
  required String fallbackKey,
}) {
  final isArabic = tr.language == AppLanguage.ar;
  final localized = (data[isArabic ? arKey : enKey] ?? '').toString().trim();
  if (localized.isNotEmpty) {
    return localized;
  }
  return (data[fallbackKey] ?? '').toString();
}

String emojiForChecklistGroupId(String? groupId) {
  switch ((groupId ?? '').trim()) {
    case 'quick_pick':
      return '⚡';
    case 'camping':
      return '🏕️';
    case 'cooking':
      return '🔥';
    case 'coffee':
      return '☕';
    case 'serving':
      return '🍽️';
    case 'food':
      return '🥩';
    case 'snacks':
      return '🍿';
    case 'entertainment':
      return '⚽';
    default:
      return '📝';
  }
}

Color checklistGroupEmojiBackgroundColor(String? groupId) {
  switch ((groupId ?? '').trim()) {
    case 'quick_pick':
      return const Color(0xFFFFF4CC);
    case 'camping':
      return const Color(0xFFE7F6E8);
    case 'cooking':
      return const Color(0xFFFFE8D9);
    case 'coffee':
      return const Color(0xFFF2E4D8);
    case 'serving':
      return const Color(0xFFFFF1E0);
    case 'food':
      return const Color(0xFFFFE5E5);
    case 'snacks':
      return const Color(0xFFFFF6D8);
    case 'entertainment':
      return const Color(0xFFE8F1FF);
    default:
      return const Color(0xFFF3F4F6);
  }
}

IconData iconFromChecklistItemId(String? itemId) {
  switch ((itemId ?? '').trim()) {
    case 'chairs':
      return Icons.chair_alt;
    case 'mat':
    case 'table_mat':
      return Icons.weekend;
    case 'dates':
    case 'bread':
    case 'maamoul':
      return Icons.bakery_dining;
    case 'coffee_thermos':
    case 'coffee_pot':
      return Icons.coffee_maker;
    case 'tea_pot':
    case 'tea_thermos':
    case 'tea':
    case 'green_tea':
      return Icons.emoji_food_beverage;
    case 'water':
      return Icons.water_drop;
    case 'hanging_light':
      return Icons.lightbulb_outline;
    case 'tent':
      return Icons.terrain;
    case 'rope_stakes':
      return Icons.link;
    case 'canopy':
      return Icons.roofing;
    case 'sleeping_mattress':
    case 'pillow':
      return Icons.bed;
    case 'foldable_table':
      return Icons.table_restaurant;
    case 'flashlight':
      return Icons.flashlight_on;
    case 'charcoal':
    case 'grill':
    case 'grill_net':
      return Icons.outdoor_grill;
    case 'firewood':
    case 'fire_starter':
    case 'gas_stove':
    case 'matches':
      return Icons.local_fire_department;
    case 'tongs':
      return Icons.construction;
    case 'skewers':
    case 'salt':
    case 'chili':
    case 'chicken':
      return Icons.restaurant;
    case 'foil':
    case 'knife':
    case 'cutting_board':
      return Icons.kitchen;
    case 'pressure_cooker':
    case 'pots':
      return Icons.soup_kitchen;
    case 'cooking_spoon':
    case 'plastic_spoons':
      return Icons.flatware;
    case 'steel_plate':
    case 'plastic_plates':
      return Icons.dining;
    case 'cleaning_liquid':
      return Icons.cleaning_services;
    case 'cups':
    case 'paper_cups':
      return Icons.local_cafe;
    case 'coffee_cardamom':
      return Icons.coffee;
    case 'coffee_spices':
    case 'mint':
    case 'basil':
    case 'spices':
      return Icons.spa;
    case 'sweetener':
      return Icons.science;
    case 'milk':
    case 'oil':
    case 'soda':
    case 'laban':
    case 'juice':
      return Icons.local_drink;
    case 'tissues':
      return Icons.dry_cleaning;
    case 'trash_bags':
      return Icons.shopping_bag;
    case 'gloves':
      return Icons.clean_hands;
    case 'rice':
      return Icons.set_meal;
    case 'meat':
      return Icons.lunch_dining;
    case 'tomato_sauce':
    case 'mayo':
    case 'ketchup':
      return Icons.local_dining;
    case 'tomatoes':
    case 'onions':
    case 'garlic':
    case 'cucumber':
    case 'lemon':
    case 'greens':
      return Icons.eco;
    case 'tahini':
    case 'cream':
    case 'yogurt':
      return Icons.breakfast_dining;
    case 'chips':
      return Icons.fastfood;
    case 'nuts':
      return Icons.grain;
    case 'ice':
      return Icons.ac_unit;
    case 'baloot':
    case 'backgammon':
      return Icons.casino;
    case 'uno':
      return Icons.sports_esports;
    case 'carrom':
    case 'chess':
      return Icons.grid_view;
    case 'domino':
      return Icons.view_module;
    case 'football':
      return Icons.sports_soccer;
    case 'volleyball':
      return Icons.sports_volleyball;
    case 'goggles':
    case 'swim_vests':
      return Icons.pool;
    default:
      return Icons.checklist;
  }
}

IconData iconFromName(String? iconName) {
  switch (iconName) {
    case 'terrain':
      return Icons.terrain;
    case 'restaurant':
      return Icons.restaurant;
    case 'chair':
    case 'chair_alt':
      return Icons.chair_alt;
    case 'water_drop':
      return Icons.water_drop;
    case 'flashlight_on':
      return Icons.flashlight_on;
    case 'lightbulb_outline':
      return Icons.lightbulb_outline;
    case 'weekend':
      return Icons.weekend;
    case 'coffee_maker':
      return Icons.coffee_maker;
    case 'link':
      return Icons.link;
    case 'roofing':
      return Icons.roofing;
    case 'bed':
      return Icons.bed;
    case 'table_restaurant':
      return Icons.table_restaurant;
    case 'outdoor_grill':
      return Icons.outdoor_grill;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'construction':
      return Icons.construction;
    case 'kitchen':
      return Icons.kitchen;
    case 'soup_kitchen':
      return Icons.soup_kitchen;
    case 'flatware':
      return Icons.flatware;
    case 'dining':
      return Icons.dining;
    case 'cleaning_services':
      return Icons.cleaning_services;
    case 'emoji_food_beverage':
      return Icons.emoji_food_beverage;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'coffee':
      return Icons.coffee;
    case 'spa':
      return Icons.spa;
    case 'science':
      return Icons.science;
    case 'local_drink':
      return Icons.local_drink;
    case 'dry_cleaning':
      return Icons.dry_cleaning;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'clean_hands':
      return Icons.clean_hands;
    case 'set_meal':
      return Icons.set_meal;
    case 'lunch_dining':
      return Icons.lunch_dining;
    case 'local_dining':
      return Icons.local_dining;
    case 'eco':
      return Icons.eco;
    case 'bakery_dining':
      return Icons.bakery_dining;
    case 'breakfast_dining':
      return Icons.breakfast_dining;
    case 'cookie':
      return Icons.cookie;
    case 'fastfood':
      return Icons.fastfood;
    case 'nutrition':
      return Icons.restaurant;
    case 'ac_unit':
      return Icons.ac_unit;
    case 'casino':
      return Icons.casino;
    case 'sports_esports':
      return Icons.sports_esports;
    case 'grid_view':
      return Icons.grid_view;
    case 'view_module':
      return Icons.view_module;
    case 'sports_soccer':
      return Icons.sports_soccer;
    case 'sports_volleyball':
      return Icons.sports_volleyball;
    case 'pool':
      return Icons.pool;
    default:
      return Icons.checklist;
  }
}

Map<String, int> categoryTemplateCounts(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> templates,
  Tr tr,
) {
  final counts = <String, int>{};
  for (final doc in templates) {
    final data = doc.data();
    final category = (data['category'] ?? tr.t('other')).toString();
    counts[category] = (counts[category] ?? 0) + 1;
  }
  return counts;
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> sortChecklistByCompletion(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
) {
  final unassignedItems = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final assignedItemsByUserId =
      <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

  for (final item in items) {
    final assignedTo = (item.data()['assignedTo'] as String?)?.trim();
    if (assignedTo == null || assignedTo.isEmpty) {
      unassignedItems.add(item);
      continue;
    }

    assignedItemsByUserId.putIfAbsent(assignedTo, () => []).add(item);
  }

  final sorted = <QueryDocumentSnapshot<Map<String, dynamic>>>[
    ..._sortChecklistGroupByCompletion(unassignedItems),
  ];
  for (final userItems in assignedItemsByUserId.values) {
    sorted.addAll(_sortChecklistGroupByCompletion(userItems));
  }

  return sorted;
}

List<QueryDocumentSnapshot<Map<String, dynamic>>>
    _sortChecklistGroupByCompletion(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
) {
  final incompleteItems = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final completedItems = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  for (final item in items) {
    if (item.data()['done'] == true) {
      completedItems.add(item);
    } else {
      incompleteItems.add(item);
    }
  }

  return <QueryDocumentSnapshot<Map<String, dynamic>>>[
    ...incompleteItems,
    ...completedItems,
  ];
}

double checklistProgressValue({
  required int doneCount,
  required int totalCount,
}) {
  if (totalCount == 0) {
    return 0;
  }
  return doneCount / totalCount;
}
