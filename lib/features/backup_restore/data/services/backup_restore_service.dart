import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../../core/storage/local_json_storage.dart';
import '../../../configuration/data/models/member_model.dart';
import '../../../configuration/data/models/profit_configuration_model.dart';
import '../../../investment/data/models/member_model.dart';
import '../../../products/data/models/product_model.dart';

class BackupRestoreService {
  BackupRestoreService(this._storage);

  final LocalJsonStorage _storage;

  static const String _appName = 'DreamsIdeAura';
  static const int _backupVersion = 1;

  Map<String, dynamic> _defaultData() {
    return <String, dynamic>{
      'members': <dynamic>[],
      'profitConfiguration': <String, dynamic>{
        'investorPercentage': 40.0,
        'effortPercentage': 40.0,
        'marketingPercentage': 20.0,
      },
      'investments': <dynamic>[],
      'products': <dynamic>[],
    };
  }

  /// Creates a complete backup file.
  ///
  /// Returns the saved file path, or null if the user cancels.
  Future<Uri?> saveBackup() async {
    final currentData = await _storage.readData();
    final completeData = _defaultData()..addAll(currentData);

    final backup = <String, dynamic>{
      'app': _appName,
      'backupVersion': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'data': completeData,
    };

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(backup),
      ),
    );

    return FilePicker.saveFile(
      dialogTitle: 'Save DreamsIdeAura backup',
      fileName: 'dreamideaura_backup_$timestamp.json',
      bytes: bytes,
    );
  }

  /// Opens a JSON file and validates it before returning its data.
  ///
  /// Returns null if the user cancels file selection.
  Future<Map<String, dynamic>?> pickAndValidateBackup() async {
    final selectedFile = await FilePicker.pickFile(
      dialogTitle: 'Select DreamsIdeAura backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (selectedFile == null) {
      return null;
    }

    final bytes = await selectedFile.readAsBytes();

    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map) {
      throw const FormatException('Invalid backup file format.');
    }

    final backup = Map<String, dynamic>.from(decoded);

    if (backup['app'] != _appName) {
      throw const FormatException(
        'This backup does not belong to DreamsIdeAura.',
      );
    }

    if (backup['backupVersion'] != _backupVersion) {
      throw const FormatException(
        'Unsupported backup version.',
      );
    }

    final rawData = backup['data'];

    if (rawData is! Map) {
      throw const FormatException(
        'Backup data is missing or invalid.',
      );
    }

    final data = Map<String, dynamic>.from(rawData);

    _validateData(data);

    // Add defaults for keys that may not have existed when the
    // backup was created. Preserve all other keys.
    return _defaultData()..addAll(data);
  }

  void _validateData(Map<String, dynamic> data) {
    final rawMembers = data['members'] ?? <dynamic>[];
    if (rawMembers is! List) {
      throw const FormatException('Invalid members data.');
    }

    for (final item in rawMembers) {
      if (item is! Map) {
        throw const FormatException('Invalid member record.');
      }

      MemberModel.fromJson(Map<String, dynamic>.from(item));
    }

    final rawConfiguration = data['profitConfiguration'];
    if (rawConfiguration != null) {
      if (rawConfiguration is! Map) {
        throw const FormatException(
          'Invalid profit configuration.',
        );
      }

      final configuration = ProfitConfigurationModel.fromJson(
        Map<String, dynamic>.from(rawConfiguration),
      );

      final percentages = [
        configuration.investorPercentage,
        configuration.effortPercentage,
        configuration.marketingPercentage,
      ];

      if (percentages.any(
        (value) => !value.isFinite || value < 0,
      )) {
        throw const FormatException(
          'Profit percentages must be valid non-negative numbers.',
        );
      }

      if ((configuration.investorPercentage +
                  configuration.effortPercentage +
                  configuration.marketingPercentage -
                  100)
              .abs() >
          0.000001) {
        throw const FormatException(
          'Profit percentages must add up to 100%.',
        );
      }
    }

    final rawInvestments = data['investments'] ?? <dynamic>[];
    if (rawInvestments is! List) {
      throw const FormatException('Invalid investments data.');
    }

    for (final item in rawInvestments) {
      if (item is! Map) {
        throw const FormatException('Invalid investment record.');
      }

      InvestmentModel.fromJson(Map<String, dynamic>.from(item));
    }

    final rawProducts = data['products'] ?? <dynamic>[];
    if (rawProducts is! List) {
      throw const FormatException('Invalid products data.');
    }

    for (final item in rawProducts) {
      if (item is! Map) {
        throw const FormatException('Invalid product record.');
      }

      final productJson = Map<String, dynamic>.from(item);
      final product = ProductModel.fromJson(productJson);
      final percentages = product.effortContributionPercentages;
      if (percentages.isNotEmpty &&
          (percentages.values.any(
                (value) => !value.isFinite || value < 0 || value > 100,
              ) ||
              (percentages.values.fold<double>(0, (sum, value) => sum + value) -
                          100)
                      .abs() >
                  0.000001 ||
              percentages.keys.toSet().difference(
                product.effortContributorIds.toSet(),
              ).isNotEmpty)) {
        throw const FormatException(
          'Invalid effort contribution percentages for a product.',
        );
      }
    }
  }

  /// Replaces all local data after the selected backup has been validated.
  Future<void> restoreBackup(Map<String, dynamic> data) async {
    _validateData(data);
    await _storage.replaceData(data);
  }

  /// Resets the app to its initial business-data state.
  Future<void> resetAppData() async {
    await _storage.replaceData(_defaultData());
  }
}
