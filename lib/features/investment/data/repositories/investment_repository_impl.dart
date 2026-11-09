
import 'package:dreamideaura/features/investment/data/models/member_model.dart';

import '../../domain/entities/investment_entity.dart';
import '../../domain/repositories/investment_repository.dart';
import '../datasources/investment_local_datasource.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  InvestmentRepositoryImpl(this._dataSource);

  final InvestmentLocalDataSource _dataSource;

  @override
  Future<List<InvestmentEntity>> getInvestments() async {
    return _dataSource.getInvestments();
  }

  @override
  Future<void> addInvestment(InvestmentEntity investment) async {
    final investments = await _dataSource.getInvestments();

    if (investments.any((item) => item.id == investment.id)) {
      throw Exception('Investment already exists.');
    }

    investments.add(InvestmentModel.fromEntity(investment));

    await _dataSource.saveInvestments(investments);
  }

  @override
  Future<void> updateInvestment(InvestmentEntity investment) async {
    final investments = await _dataSource.getInvestments();

    final index = investments.indexWhere(
      (item) => item.id == investment.id,
    );

    if (index == -1) {
      throw Exception('Investment not found.');
    }

    investments[index] = InvestmentModel.fromEntity(investment);

    await _dataSource.saveInvestments(investments);
  }

  @override
  Future<void> deleteInvestment(String investmentId) async {
    final investments = await _dataSource.getInvestments();

    investments.removeWhere(
      (item) => item.id == investmentId,
    );

    await _dataSource.saveInvestments(investments);
  }
}
