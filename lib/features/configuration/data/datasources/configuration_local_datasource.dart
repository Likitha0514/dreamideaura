
import '../../../../core/storage/local_json_storage.dart';
import '../models/member_model.dart';
import '../models/profit_configuration_model.dart';

class ConfigurationLocalDataSource {
  ConfigurationLocalDataSource(this._storage);

  final LocalJsonStorage _storage;

  static const String _membersKey = 'members';
  static const String _profitKey = 'profitConfiguration';

  Future<List<MemberModel>> getMembers() async {
    final data = await _storage.readData();
    final rawMembers = data[_membersKey] as List<dynamic>? ?? [];

    return rawMembers.map((item) {
      return MemberModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  Future<void> saveMembers(List<MemberModel> members) async {
    final data = await _storage.readData();

    data[_membersKey] = members.map((member) => member.toJson()).toList();

    await _storage.writeData(data);
  }

  Future<ProfitConfigurationModel> getProfitConfiguration() async {
    final data = await _storage.readData();
    final raw = data[_profitKey];

    if (raw == null) {
      return const ProfitConfigurationModel(
        investorPercentage: 40,
        effortPercentage: 40,
        marketingPercentage: 20,
      );
    }

    return ProfitConfigurationModel.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  Future<void> saveProfitConfiguration(
    ProfitConfigurationModel configuration,
  ) async {
    final data = await _storage.readData();

    data[_profitKey] = configuration.toJson();

    await _storage.writeData(data);
  }
}
