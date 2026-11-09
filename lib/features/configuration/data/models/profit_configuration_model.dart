
import '../../domain/entities/profit_configuration_entity.dart';

class ProfitConfigurationModel extends ProfitConfigurationEntity {
  const ProfitConfigurationModel({
    required super.investorPercentage,
    required super.effortPercentage,
    required super.marketingPercentage,
  });

  factory ProfitConfigurationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfitConfigurationModel(
      investorPercentage: (json['investorPercentage'] as num).toDouble(),
      effortPercentage: (json['effortPercentage'] as num).toDouble(),
      marketingPercentage: (json['marketingPercentage'] as num).toDouble(),
    );
  }

  factory ProfitConfigurationModel.fromEntity(
    ProfitConfigurationEntity entity,
  ) {
    return ProfitConfigurationModel(
      investorPercentage: entity.investorPercentage,
      effortPercentage: entity.effortPercentage,
      marketingPercentage: entity.marketingPercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'investorPercentage': investorPercentage,
      'effortPercentage': effortPercentage,
      'marketingPercentage': marketingPercentage,
    };
  }
}
