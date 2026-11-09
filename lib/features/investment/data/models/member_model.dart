
import '../../domain/entities/investment_entity.dart';

class InvestmentModel extends InvestmentEntity {
  const InvestmentModel({
    required super.id,
    required super.memberId,
    required super.amount,
    required super.date,
    required super.description,
  });

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String? ?? '',
    );
  }

  factory InvestmentModel.fromEntity(InvestmentEntity entity) {
    return InvestmentModel(
      id: entity.id,
      memberId: entity.memberId,
      amount: entity.amount,
      date: entity.date,
      description: entity.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}
