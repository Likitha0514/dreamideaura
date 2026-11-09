class ProductEntity {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.sellingPrice,
    required this.date,
    required this.effortContributorIds,
    required this.marketingContributorIds,
    this.effortContributionPercentages = const <String, double>{},
  });

  final String id;
  final String name;
  final double sellingPrice;
  final DateTime date;
  final List<String> effortContributorIds;
  final List<String> marketingContributorIds;

  /// Product-specific percentage of the effort pool allocated to each member.
  /// An empty map means equal distribution for backward compatibility.
  final Map<String, double> effortContributionPercentages;

  Map<String, double> get resolvedEffortContributionPercentages {
    final ids = effortContributorIds.toSet().toList()..sort();
    if (ids.isEmpty) return const <String, double>{};

    final saved = effortContributionPercentages;
    final isComplete = saved.length == ids.length &&
        ids.every((id) => saved.containsKey(id)) &&
        saved.values.every((value) => value.isFinite && value >= 0) &&
        (saved.values.fold<double>(0, (sum, value) => sum + value) - 100)
                .abs() <
            0.000001;

    if (isComplete) return saved;

    final equalShare = 100 / ids.length;
    return <String, double>{
      for (var index = 0; index < ids.length; index++)
        ids[index]: index == ids.length - 1
            ? 100 - equalShare * (ids.length - 1)
            : equalShare,
    };
  }
}