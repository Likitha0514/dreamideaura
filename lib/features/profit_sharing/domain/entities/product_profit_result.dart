import 'member_product_earning.dart';

class ProductProfitResult {
  const ProductProfitResult({
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.investorPool,
    required this.effortPool,
    required this.marketingPool,
    required this.memberEarnings,
  });

  final String productId;
  final String productName;
  final double sellingPrice;

  final double investorPool;
  final double effortPool;
  final double marketingPool;

  final List<MemberProductEarning> memberEarnings;

  double get totalDistributed => memberEarnings.fold<double>(
        0,
        (total, earning) => total + earning.totalShare,
      );
}