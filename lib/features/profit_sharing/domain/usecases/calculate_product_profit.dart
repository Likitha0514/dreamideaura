import '../../../configuration/domain/entities/member_entity.dart';
import '../../../configuration/domain/entities/profit_configuration_entity.dart';
import '../../../investment/domain/entities/investment_entity.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../entities/member_product_earning.dart';
import '../entities/product_profit_result.dart';

class CalculateProductProfit {
  ProductProfitResult call({
    required ProductEntity product,
    required List<MemberEntity> members,
    required List<InvestmentEntity> investments,
    required ProfitConfigurationEntity configuration,
  }) {
    if (!configuration.isValid) {
      throw ArgumentError(
        'Profit percentages must total exactly 100%.',
      );
    }

    if (!product.sellingPrice.isFinite || product.sellingPrice < 0) {
      throw ArgumentError('Invalid product selling price.');
    }

    final activeMemberIds = members
        .where((member) => member.isActive)
        .map((member) => member.id)
        .toSet()
        .toList()
      ..sort();

    final memberMap = {
      for (final member in members) member.id: member,
    };

    final investorIds = investments
        .map((investment) => investment.memberId)
        .toSet()
        .toList()
      ..sort();

    final effortIds = product.effortContributorIds.toSet().toList()
      ..sort();

    final marketingIds =
        product.marketingContributorIds.toSet().toList()..sort();

    final totalCents = (product.sellingPrice * 100).round();

    // Calculate category pools in paise.
    final pools = _calculateCategoryPools(
      totalCents: totalCents,
      percentages: [
        configuration.investorPercentage,
        configuration.effortPercentage,
        configuration.marketingPercentage,
      ],
    );

    // A category with no contributors uses all active members.
    final investorRecipients = _resolveRecipients(
      investorIds,
      activeMemberIds,
      memberMap,
    );

    final effortRecipients = _resolveRecipients(
      effortIds,
      activeMemberIds,
      memberMap,
    );

    final marketingRecipients = _resolveRecipients(
      marketingIds,
      activeMemberIds,
      memberMap,
    );

    final investorShares = _splitPool(
      pools[0],
      investorRecipients,
    );

    final effortShares = _splitEffortPool(
      pools[1],
      effortRecipients,
      product.resolvedEffortContributionPercentages,
    );

    final marketingShares = _splitPool(
      pools[2],
      marketingRecipients,
    );

    final allMemberIds = <String>{
      ...investorShares.keys,
      ...effortShares.keys,
      ...marketingShares.keys,
    }.toList()
      ..sort();

    final earnings = allMemberIds.map((memberId) {
      final member = memberMap[memberId]!;

      return MemberProductEarning(
        memberId: memberId,
        memberName: member.name,
        productId: product.id,
        productName: product.name,
        productSellingPrice: totalCents / 100,
        investorShare: (investorShares[memberId] ?? 0) / 100,
        effortShare: (effortShares[memberId] ?? 0) / 100,
        marketingShare: (marketingShares[memberId] ?? 0) / 100,
      );
    }).toList();

    return ProductProfitResult(
      productId: product.id,
      productName: product.name,
      sellingPrice: totalCents / 100,
      investorPool: pools[0] / 100,
      effortPool: pools[1] / 100,
      marketingPool: pools[2] / 100,
      memberEarnings: earnings,
    );
  }

  List<int> _calculateCategoryPools({
    required int totalCents,
    required List<double> percentages,
  }) {
    final exactAmounts = percentages
        .map((percentage) => totalCents * percentage / 100)
        .toList();

    final pools = exactAmounts.map((amount) => amount.floor()).toList();

    var remainingCents = totalCents - pools.fold<int>(
      0,
      (total, amount) => total + amount,
    );

    final indexes = [0, 1, 2];

    // Give leftover paise to categories with the largest fractions.
    indexes.sort((a, b) {
      final difference =
          (exactAmounts[b] - exactAmounts[b].floor()) -
          (exactAmounts[a] - exactAmounts[a].floor());

      if (difference != 0) {
        return difference > 0 ? 1 : -1;
      }

      return a.compareTo(b);
    });

    for (var i = 0; i < remainingCents; i++) {
      pools[indexes[i]]++;
    }

    return pools;
  }

  List<String> _resolveRecipients(
    List<String> requestedIds,
    List<String> activeMemberIds,
    Map<String, MemberEntity> memberMap,
  ) {
    final validIds = requestedIds
        .where((id) => memberMap.containsKey(id))
        .toSet()
        .toList()
      ..sort();

    if (validIds.isNotEmpty) {
      return validIds;
    }

    if (activeMemberIds.isEmpty) {
      throw StateError(
        'No eligible members available to distribute a profit category.',
      );
    }

    return activeMemberIds;
  }


  /// Splits the effort pool using the product-specific contribution weights.
  /// Missing/invalid legacy weights fall back to an equal split.
  Map<String, int> _splitEffortPool(
    int poolCents,
    List<String> recipientIds,
    Map<String, double> percentages,
  ) {
    if (recipientIds.isEmpty) {
      if (poolCents == 0) return {};
      throw StateError('Cannot distribute a pool without recipients.');
    }

    final ids = recipientIds.toSet().toList()..sort();
    final weights = ids.map((id) => percentages[id] ?? 0).toList();
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    final validWeights = weights.every((value) => value.isFinite && value >= 0) &&
        totalWeight > 0 && (totalWeight - 100).abs() < 0.000001;

    final effectiveWeights = validWeights
        ? weights.map((weight) => weight * 100 / totalWeight).toList()
        : List<double>.filled(ids.length, 100 / ids.length);
    final exactShares = effectiveWeights
        .map((weight) => poolCents * weight / 100)
        .toList();
    final shares = exactShares.map((amount) => amount.floor()).toList();
    var remaining = poolCents - shares.fold<int>(0, (sum, value) => sum + value);
    final indexes = List<int>.generate(ids.length, (index) => index)
      ..sort((a, b) {
        final fractionA = exactShares[a] - exactShares[a].floor();
        final fractionB = exactShares[b] - exactShares[b].floor();
        final comparison = fractionB.compareTo(fractionA);
        return comparison != 0 ? comparison : ids[a].compareTo(ids[b]);
      });

    for (var index = 0; index < remaining; index++) {
      shares[indexes[index]]++;
    }

    return <String, int>{
      for (var index = 0; index < ids.length; index++) ids[index]: shares[index],
    };
  }

  Map<String, int> _splitPool(
    int poolCents,
    List<String> recipientIds,
  ) {
    if (recipientIds.isEmpty) {
      if (poolCents == 0) return {};
      throw StateError('Cannot distribute a pool without recipients.');
    }

    final sortedIds = recipientIds.toSet().toList()..sort();

    final baseShare = poolCents ~/ sortedIds.length;
    final remainingCents = poolCents % sortedIds.length;

    return {
      for (var i = 0; i < sortedIds.length; i++)
        sortedIds[i]: baseShare + (i < remainingCents ? 1 : 0),
    };
  }
}