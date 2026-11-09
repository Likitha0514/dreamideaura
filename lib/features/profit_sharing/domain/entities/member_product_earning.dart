class MemberProductEarning {
  const MemberProductEarning({
    required this.memberId,
    required this.memberName,
    required this.productId,
    required this.productName,
    required this.productSellingPrice,
    required this.investorShare,
    required this.effortShare,
    required this.marketingShare,
  });

  final String memberId;
  final String memberName;
  final String productId;
  final String productName;
  final double productSellingPrice;

  final double investorShare;
  final double effortShare;
  final double marketingShare;

  double get totalShare =>
      investorShare + effortShare + marketingShare;
}