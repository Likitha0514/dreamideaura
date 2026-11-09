
import 'package:dreamideaura/features/investment/data/models/member_model.dart';

import '../../../../core/storage/local_json_storage.dart';

class InvestmentLocalDataSource {
  InvestmentLocalDataSource(this._storage);

  final LocalJsonStorage _storage;

  static const String _investmentsKey = 'investments';

  Future<List<InvestmentModel>> getInvestments() async {
    final data = await _storage.readData();

    final rawInvestments =
        data[_investmentsKey] as List<dynamic>? ?? [];

    return rawInvestments.map((item) {
      return InvestmentModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  Future<void> saveInvestments(
    List<InvestmentModel> investments,
  ) async {
    final data = await _storage.readData();

    data[_investmentsKey] =
        investments.map((item) => item.toJson()).toList();

    await _storage.writeData(data);
  }
}
