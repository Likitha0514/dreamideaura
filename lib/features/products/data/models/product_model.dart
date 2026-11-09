import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.sellingPrice,
    required super.date,
    required super.effortContributorIds,
    required super.marketingContributorIds,
    super.effortContributionPercentages = const <String, double>{},
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawPercentages = json['effortContributionPercentages'];
    final percentages = <String, double>{};

    if (rawPercentages is Map) {
      for (final entry in rawPercentages.entries) {
        if (entry.value is num) {
          percentages[entry.key.toString()] =
              (entry.value as num).toDouble();
        }
      }
    }

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      effortContributorIds:
          List<String>.from(json['effortContributorIds'] as List? ?? []),
      marketingContributorIds:
          List<String>.from(json['marketingContributorIds'] as List? ?? []),
      effortContributionPercentages: percentages,
    );
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      sellingPrice: entity.sellingPrice,
      date: entity.date,
      effortContributorIds: entity.effortContributorIds,
      marketingContributorIds: entity.marketingContributorIds,
      effortContributionPercentages:
          entity.resolvedEffortContributionPercentages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sellingPrice': sellingPrice,
      'date': date.toIso8601String(),
      'effortContributorIds': effortContributorIds,
      'marketingContributorIds': marketingContributorIds,
      'effortContributionPercentages':
          resolvedEffortContributionPercentages,
    };
  }
}