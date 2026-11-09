
import 'package:flutter/material.dart';

import '../../../../core/storage/local_json_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/configuration_local_datasource.dart';
import '../../data/repositories/configuration_repository_impl.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/entities/profit_configuration_entity.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() =>
      _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  late final ConfigurationRepositoryImpl _repository;

  final TextEditingController _investorController =
      TextEditingController();

  final TextEditingController _effortController =
      TextEditingController();

  final TextEditingController _marketingController =
      TextEditingController();

  List<MemberEntity> _members = [];

  bool _isLoading = true;
  bool _isSavingPercentages = false;

  @override
  void initState() {
    super.initState();

    _repository = ConfigurationRepositoryImpl(
      ConfigurationLocalDataSource(
        LocalJsonStorage(),
      ),
    );

    _investorController.addListener(_refreshPercentageTotal);
    _effortController.addListener(_refreshPercentageTotal);
    _marketingController.addListener(_refreshPercentageTotal);

    _loadConfiguration();
  }

  @override
  void dispose() {
    _investorController.removeListener(_refreshPercentageTotal);
    _effortController.removeListener(_refreshPercentageTotal);
    _marketingController.removeListener(_refreshPercentageTotal);

    _investorController.dispose();
    _effortController.dispose();
    _marketingController.dispose();

    super.dispose();
  }

  void _refreshPercentageTotal() {
    if (mounted) {
      setState(() {});
    }
  }

  // Load members and profit configuration.
  Future<void> _loadConfiguration() async {
    try {
      final List<MemberEntity> members =
          await _repository.getMembers();

      final ProfitConfigurationEntity configuration =
          await _repository.getProfitConfiguration();

      if (!mounted) return;

      setState(() {
        _members = members;

        _investorController.text =
            configuration.investorPercentage.toString();

        _effortController.text =
            configuration.effortPercentage.toString();

        _marketingController.text =
            configuration.marketingPercentage.toString();

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load configuration: $error');
    }
  }

  // Add a new business member.
  Future<void> _addMember(String name) async {
    final DateTime now = DateTime.now();

    final MemberEntity member = MemberEntity(
      id: 'member_${now.microsecondsSinceEpoch}',
      name: name,
      isActive: true,
      createdAt: now,
    );

    try {
      await _repository.saveMember(member);
      await _refreshMembers();

      if (mounted) {
        _showMessage('Member added successfully.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to add member: $error');
      }
    }
  }

  // Edit an existing member name.
  Future<void> _editMember(
    MemberEntity member,
    String name,
  ) async {
    final MemberEntity updatedMember = MemberEntity(
      id: member.id,
      name: name,
      isActive: member.isActive,
      createdAt: member.createdAt,
    );

    try {
      await _repository.updateMember(updatedMember);
      await _refreshMembers();

      if (mounted) {
        _showMessage('Member updated successfully.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to update member: $error');
      }
    }
  }

  // Activate or deactivate a member.
  Future<void> _changeMemberStatus(MemberEntity member) async {
    final bool newStatus = !member.isActive;

    try {
      await _repository.updateMemberStatus(
        member.id,
        newStatus,
      );

      await _refreshMembers();

      if (mounted) {
        _showMessage(
          newStatus
              ? 'Member activated successfully.'
              : 'Member deactivated successfully.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to update member status: $error');
      }
    }
  }

  // Refresh members from local storage.
  Future<void> _refreshMembers() async {
    final List<MemberEntity> members =
        await _repository.getMembers();

    if (!mounted) return;

    setState(() {
      _members = members;
    });
  }

  // Save profit percentage configuration.
  Future<void> _savePercentages() async {
    final double? investor =
        double.tryParse(_investorController.text.trim());

    final double? effort =
        double.tryParse(_effortController.text.trim());

    final double? marketing =
        double.tryParse(_marketingController.text.trim());

    if (investor == null ||
        effort == null ||
        marketing == null) {
      _showMessage('Please enter valid percentage values.');
      return;
    }

    final ProfitConfigurationEntity configuration =
        ProfitConfigurationEntity(
      investorPercentage: investor,
      effortPercentage: effort,
      marketingPercentage: marketing,
    );

    if (!configuration.isValid) {
      _showMessage(
        'All percentages must be non-negative and total 100%.',
      );
      return;
    }

    setState(() {
      _isSavingPercentages = true;
    });

    try {
      await _repository.saveProfitConfiguration(configuration);

      if (mounted) {
        _showMessage('Profit percentages saved successfully.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to save percentages: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPercentages = false;
        });
      }
    }
  }

  // Add or edit member dialog.
  void _showMemberDialog({MemberEntity? member}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _MemberDialog(
          member: member,
          onSave: (name) {
            if (member != null) {
              _editMember(member, name);
            } else {
              _addMember(name);
            }
          },
        );
      },
    );
  }

  // Display snackbar message.
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount =
        _members.where((member) => member.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadConfiguration,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(
                    'Business Members',
                    '$activeCount active members',
                  ),
                  const SizedBox(height: 16),
                  _buildMemberSection(),
                  const SizedBox(height: 32),
                  _buildHeader(
                    'Profit Distribution',
                    'Configure percentage allocation',
                  ),
                  const SizedBox(height: 16),
                  _buildProfitSection(),
                ],
              ),
            ),
    );
  }

  // Section heading.
  Widget _buildHeader(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // Member management section.
  Widget _buildMemberSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Manage Members',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showMemberDialog(),
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No members added yet.\n'
                'Add your first business member.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            ..._members.map(_buildMemberTile),
        ],
      ),
    );
  }

  // Individual member item.
  Widget _buildMemberTile(MemberEntity member) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                AppTheme.primary.withValues(alpha: 0.12),
            child: Text(
              member.name.isEmpty
                  ? '?'
                  : member.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: member.isActive
                        ? Colors.green
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit member',
            onPressed: () {
              _showMemberDialog(member: member);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Member options',
            onSelected: (value) {
              if (value == 'status') {
                _changeMemberStatus(member);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'status',
                child: Text(
                  member.isActive ? 'Deactivate' : 'Activate',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Profit percentage section.
  Widget _buildProfitSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPercentageField(
            label: 'Investors',
            controller: _investorController,
          ),
          const SizedBox(height: 16),
          _buildPercentageField(
            label: 'Efforts',
            controller: _effortController,
          ),
          const SizedBox(height: 16),
          _buildPercentageField(
            label: 'Marketing',
            controller: _marketingController,
          ),
          const SizedBox(height: 20),
          _buildPercentageTotal(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingPercentages
                  ? null
                  : _savePercentages,
              child: _isSavingPercentages
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Percentages'),
            ),
          ),
        ],
      ),
    );
  }

  // Individual percentage input.
  Widget _buildPercentageField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
      ),
    );
  }

  // Live percentage total.
  Widget _buildPercentageTotal() {
    final double investor =
        double.tryParse(_investorController.text) ?? 0;

    final double effort =
        double.tryParse(_effortController.text) ?? 0;

    final double marketing =
        double.tryParse(_marketingController.text) ?? 0;

    final double total = investor + effort + marketing;

    final bool isValid =
        (total - 100).abs() < 0.000001 &&
        investor >= 0 &&
        effort >= 0 &&
        marketing >= 0;

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Total Allocation',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${total.toStringAsFixed(2)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isValid ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          size: 18,
          color: isValid ? Colors.green : Colors.red,
        ),
      ],
    );
  }
}

// Separate stateful dialog to manage the member name controller lifecycle.
class _MemberDialog extends StatefulWidget {
  const _MemberDialog({
    required this.member,
    required this.onSave,
  });

  final MemberEntity? member;
  final ValueChanged<String> onSave;

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  late final TextEditingController _controller;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.member?.name ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _controller.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop();
    widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Member' : 'Add Member',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Member Name',
          hintText: 'Enter member name',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(
            _isEditing ? 'Update' : 'Add',
          ),
        ),
      ],
    );
  }
}
