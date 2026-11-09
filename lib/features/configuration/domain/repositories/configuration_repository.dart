
import 'package:dreamideaura/features/configuration/domain/entities/member_entity.dart';
import 'package:dreamideaura/features/configuration/domain/entities/profit_configuration_entity.dart';

abstract class ConfigurationRepository {
  Future<List<MemberEntity>> getMembers();

  Future<void> saveMember(MemberEntity member);

  Future<void> updateMember(MemberEntity member);

  Future<void> updateMemberStatus(String memberId, bool isActive);

  Future<ProfitConfigurationEntity> getProfitConfiguration();

  Future<void> saveProfitConfiguration(
    ProfitConfigurationEntity configuration,
  );
}
