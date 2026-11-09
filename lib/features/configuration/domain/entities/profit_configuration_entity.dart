
class ProfitConfigurationEntity {
  const ProfitConfigurationEntity({
    required this.investorPercentage,
    required this.effortPercentage,
    required this.marketingPercentage,
  });

  final double investorPercentage;
  final double effortPercentage;
  final double marketingPercentage;

  double get totalPercentage =>
      investorPercentage + effortPercentage + marketingPercentage;

  bool get isValid =>
      investorPercentage >= 0 &&
      effortPercentage >= 0 &&
      marketingPercentage >= 0 &&
      (totalPercentage - 100).abs() < 0.000001;

  factory ProfitConfigurationEntity.defaults() {
    return const ProfitConfigurationEntity(
      investorPercentage: 40,
      effortPercentage: 40,
      marketingPercentage: 20,
    );
  }
}
