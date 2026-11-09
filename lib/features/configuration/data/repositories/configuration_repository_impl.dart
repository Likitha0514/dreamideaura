
import '../../domain/entities/member_entity.dart';
import '../../domain/entities/profit_configuration_entity.dart';
import '../../domain/repositories/configuration_repository.dart';
import '../datasources/configuration_local_datasource.dart';
import '../models/member_model.dart';
import '../models/profit_configuration_model.dart';

class ConfigurationRepositoryImpl implements ConfigurationRepository {
  ConfigurationRepositoryImpl(this._dataSource);

  final ConfigurationLocalDataSource _dataSource;

  @override
  Future<List<MemberEntity>> getMembers() async {
    return _dataSource.getMembers();
  }

  @override
  Future<void> saveMember(MemberEntity member) async {
    final members = await _dataSource.getMembers();

    if (members.any((item) => item.id == member.id)) {
      throw Exception('Member already exists.');
    }

    members.add(_toModel(member));
    await _dataSource.saveMembers(members);
  }

  @override
  Future<void> updateMember(MemberEntity member) async {
    final members = await _dataSource.getMembers();
    final index = members.indexWhere((item) => item.id == member.id);

    if (index == -1) {
      throw Exception('Member not found.');
    }

    members[index] = _toModel(member);
    await _dataSource.saveMembers(members);
  }

  @override
  Future<void> updateMemberStatus(
    String memberId,
    bool isActive,
  ) async {
    final members = await _dataSource.getMembers();
    final index = members.indexWhere((item) => item.id == memberId);

    if (index == -1) {
      throw Exception('Member not found.');
    }

    final oldMember = members[index];

    members[index] = MemberModel(
      id: oldMember.id,
      name: oldMember.name,
      isActive: isActive,
      createdAt: oldMember.createdAt,
    );

    await _dataSource.saveMembers(members);
  }

  @override
  Future<ProfitConfigurationEntity> getProfitConfiguration() {
    return _dataSource.getProfitConfiguration();
  }

  @override
  Future<void> saveProfitConfiguration(
    ProfitConfigurationEntity configuration,
  ) async {
    if (!configuration.isValid) {
      throw ArgumentError('The percentages must total 100%.');
    }

    await _dataSource.saveProfitConfiguration(
      ProfitConfigurationModel.fromEntity(configuration),
    );
  }

  MemberModel _toModel(MemberEntity member) {
    return MemberModel(
      id: member.id,
      name: member.name,
      isActive: member.isActive,
      createdAt: member.createdAt,
    );
  }
}
