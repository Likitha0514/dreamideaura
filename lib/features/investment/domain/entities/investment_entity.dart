
class InvestmentEntity {
  const InvestmentEntity({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.date,
    required this.description,
  });

  final String id;
  final String memberId;
  final double amount;
  final DateTime date;
  final String description;
}
