import 'package:flutter_test/flutter_test.dart';
import 'package:dreamideaura/features/configuration/domain/entities/member_entity.dart';
import 'package:dreamideaura/features/investment/domain/entities/investment_entity.dart';
import 'package:dreamideaura/features/products/domain/entities/product_entity.dart';
import 'package:dreamideaura/features/profit_sharing/domain/entities/profit_configuration_entity.dart';
import 'package:dreamideaura/features/profit_sharing/domain/profit_calculator.dart';

void main() {
  final DateTime date = DateTime(2026, 11, 4);
  final List<MemberEntity> members = <MemberEntity>[
    MemberEntity(id: 'M1', name: 'A', isActive: true, createdAt: date),
    MemberEntity(id: 'M2', name: 'B', isActive: true, createdAt: date),
    MemberEntity(id: 'M3', name: 'C', isActive: true, createdAt: date),
  ];
  const ProfitConfigurationEntity configuration = ProfitConfigurationEntity(
    investorPercentage: 40,
    effortPercentage: 40,
    marketingPercentage: 20,
  );

  test('allocates product selling price exactly across all categories', () {
    final ProductEntity product = ProductEntity(
      id: 'P1',
      name: 'Crochet bouquet',
      sellingPricePaise: 100000,
      date: date,
      effortMemberIds: <String>['M1', 'M2'],
      marketingMemberIds: <String>['M3'],
    );
    final List<InvestmentEntity> investments = <InvestmentEntity>[
      InvestmentEntity(id: 'I1', memberId: 'M1', amountPaise: 500000, date: date, description: ''),
      InvestmentEntity(id: 'I2', memberId: 'M2', amountPaise: 300000, date: date, description: ''),
      InvestmentEntity(id: 'I3', memberId: 'M3', amountPaise: 200000, date: date, description: ''),
    ];

    final result = ProfitCalculator().calculateProduct(
      product: product,
      members: members,
      investments: investments,
      configuration: configuration,
    );

    expect(result.fold<int>(0, (sum, earning) => sum + earning.totalPaise), 100000);
    expect(result.firstWhere((e) => e.memberId == 'M1').effortSharePaise, 20000);
    expect(result.firstWhere((e) => e.memberId == 'M3').marketingSharePaise, 20000);
  });

  test('uses all active members when a category has no contributors', () {
    final ProductEntity product = ProductEntity(
      id: 'P2',
      name: 'Crochet rose',
      sellingPricePaise: 100000,
      date: date,
      effortMemberIds: <String>['M1'],
      marketingMemberIds: <String>[],
    );
    final List<InvestmentEntity> investments = <InvestmentEntity>[
      InvestmentEntity(id: 'I1', memberId: 'M1', amountPaise: 100000, date: date, description: ''),
    ];

    final result = ProfitCalculator().calculateProduct(
      product: product,
      members: members,
      investments: investments,
      configuration: configuration,
    );

    expect(result.fold<int>(0, (sum, earning) => sum + earning.totalPaise), 100000);
    // Marketing's 20% fallback is divided equally among all three active members.
    expect(result.firstWhere((e) => e.memberId == 'M1').marketingSharePaise, 6667);
    expect(result.firstWhere((e) => e.memberId == 'M2').marketingSharePaise, 6667);
    expect(result.firstWhere((e) => e.memberId == 'M3').marketingSharePaise, 6666);
  });
}
