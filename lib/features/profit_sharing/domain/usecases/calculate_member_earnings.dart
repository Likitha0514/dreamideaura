import '../entities/member_product_earning.dart';
import '../entities/product_profit_result.dart';

class CalculateMemberEarnings {
  List<MemberProductEarning> call({
    required List<ProductProfitResult> productResults,
  }) {
    final earnings = <String, MemberProductEarning>{};

    for (final result in productResults) {
      for (final earning in result.memberEarnings) {
        final existing = earnings[earning.memberId];

        if (existing == null) {
          earnings[earning.memberId] = MemberProductEarning(
            memberId: earning.memberId,
            memberName: earning.memberName,
            productId: '',
            productName: 'All selected products',
            productSellingPrice: 0,
            investorShare: earning.investorShare,
            effortShare: earning.effortShare,
            marketingShare: earning.marketingShare,
          );
        } else {
          earnings[earning.memberId] = MemberProductEarning(
            memberId: existing.memberId,
            memberName: existing.memberName,
            productId: '',
            productName: 'All selected products',
            productSellingPrice: 0,
            investorShare:
                existing.investorShare + earning.investorShare,
            effortShare:
                existing.effortShare + earning.effortShare,
            marketingShare:
                existing.marketingShare + earning.marketingShare,
          );
        }
      }
    }

    final result = earnings.values.toList()
      ..sort((a, b) => a.memberName.compareTo(b.memberName));

    return result;
  }
}