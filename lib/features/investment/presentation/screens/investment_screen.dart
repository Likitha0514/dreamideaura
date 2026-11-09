
import 'package:flutter/material.dart';

import '../../../../core/storage/local_json_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../configuration/data/datasources/configuration_local_datasource.dart';
import '../../../configuration/data/repositories/configuration_repository_impl.dart';
import '../../../configuration/domain/entities/member_entity.dart';
import '../../data/datasources/investment_local_datasource.dart';
import '../../data/repositories/investment_repository_impl.dart';
import '../../domain/entities/investment_entity.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  late final InvestmentRepositoryImpl _investmentRepository;
  late final ConfigurationRepositoryImpl _configurationRepository;

  List<InvestmentEntity> _investments = [];
  List<MemberEntity> _members = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final storage = LocalJsonStorage();

    _investmentRepository = InvestmentRepositoryImpl(
      InvestmentLocalDataSource(storage),
    );

    _configurationRepository = ConfigurationRepositoryImpl(
      ConfigurationLocalDataSource(storage),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _investmentRepository.getInvestments(),
        _configurationRepository.getMembers(),
      ]);

      if (!mounted) return;

      setState(() {
        _investments = results[0] as List<InvestmentEntity>;
        _members = results[1] as List<MemberEntity>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load investments: $error');
    }
  }

  Future<void> _refreshData() async {
    try {
      final results = await Future.wait([
        _investmentRepository.getInvestments(),
        _configurationRepository.getMembers(),
      ]);

      if (!mounted) return;

      setState(() {
        _investments = results[0] as List<InvestmentEntity>;
        _members = results[1] as List<MemberEntity>;
      });
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to refresh investments: $error');
      }
    }
  }

  double get _totalInvestment {
    return _investments.fold(
      0,
      (total, investment) => total + investment.amount,
    );
  }

  List<MemberEntity> get _activeMembers {
    return _members.where((member) => member.isActive).toList();
  }

  double _memberTotal(String memberId) {
    return _investments
        .where((investment) => investment.memberId == memberId)
        .fold(
          0,
          (total, investment) => total + investment.amount,
        );
  }

  MemberEntity? _findMember(String memberId) {
    for (final member in _members) {
      if (member.id == memberId) {
        return member;
      }
    }

    return null;
  }

  String _memberName(String memberId) {
    return _findMember(memberId)?.name ?? 'Unknown member';
  }

  Future<void> _showInvestmentDialog({
    InvestmentEntity? investment,
  }) async {
    final List<MemberEntity> availableMembers = [
      ..._activeMembers,
    ];

    // Keep an existing inactive member available when editing
    // their historical investment.
    if (investment != null &&
        !availableMembers.any(
          (member) => member.id == investment.memberId,
        )) {
      final existingMember = _findMember(investment.memberId);

      if (existingMember != null) {
        availableMembers.add(existingMember);
      }
    }

    if (availableMembers.isEmpty) {
      _showMessage('Please add an active member in Configuration first.');
      return;
    }

    final result = await showDialog<InvestmentEntity>(
      context: context,
      builder: (dialogContext) {
        return _InvestmentFormDialog(
          members: availableMembers,
          investment: investment,
        );
      },
    );

    if (result == null) return;

    try {
      if (investment == null) {
        await _investmentRepository.addInvestment(result);
      } else {
        await _investmentRepository.updateInvestment(result);
      }

      await _refreshData();

      if (mounted) {
        _showMessage(
          investment == null
              ? 'Investment added successfully.'
              : 'Investment updated successfully.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to save investment: $error');
      }
    }
  }

  Future<void> _deleteInvestment(
    InvestmentEntity investment,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Investment'),
          content: const Text(
            'Are you sure you want to delete this investment record?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _investmentRepository.deleteInvestment(investment.id);
      await _refreshData();

      if (mounted) {
        _showMessage('Investment deleted successfully.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to delete investment: $error');
      }
    }
  }

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

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Investments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInvestmentDialog(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Investment'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Member-wise Investments'),
                  const SizedBox(height: 12),
                  _buildMemberTotals(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Investment History'),
                  const SizedBox(height: 12),
                  _buildInvestmentHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9B6DFF),
            Color(0xFF7650D9),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Business Investment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatAmount(_totalInvestment),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_investments.length} investment records',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildMemberTotals() {
    if (_members.isEmpty) {
      return _buildEmptyState('No members added yet.');
    }

    final membersWithInvestments = _members.where(
      (member) => _memberTotal(member.id) > 0,
    ).toList();

    if (membersWithInvestments.isEmpty) {
      return _buildEmptyState(
        'No investments recorded yet.',
      );
    }

    return Column(
      children: membersWithInvestments.map((member) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
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
                child: Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatAmount(_memberTotal(member.id)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvestmentHistory() {
    if (_investments.isEmpty) {
      return _buildEmptyState(
        'No investments yet.\nAdd your first investment.',
      );
    }

    final sortedInvestments = [..._investments]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: sortedInvestments.map((investment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _memberName(investment.memberId),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(investment.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (investment.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        investment.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatAmount(investment.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showInvestmentDialog(
                      investment: investment,
                    );
                  } else if (value == 'delete') {
                    _deleteInvestment(investment);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// Stateful dialog owns its controllers and disposes them safely.
class _InvestmentFormDialog extends StatefulWidget {
  const _InvestmentFormDialog({
    required this.members,
    this.investment,
  });

  final List<MemberEntity> members;
  final InvestmentEntity? investment;

  @override
  State<_InvestmentFormDialog> createState() =>
      _InvestmentFormDialogState();
}

class _InvestmentFormDialogState
    extends State<_InvestmentFormDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _selectedMemberId;
  late DateTime _selectedDate;

  bool get _isEditing => widget.investment != null;

  @override
  void initState() {
    super.initState();

    final investment = widget.investment;

    _selectedMemberId =
        investment?.memberId ?? widget.members.first.id;

    _selectedDate = investment?.date ?? DateTime.now();

    _amountController = TextEditingController(
      text: investment == null
          ? ''
          : investment.amount.toString(),
    );

    _descriptionController = TextEditingController(
      text: investment?.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero.'),
        ),
      );
      return;
    }

    final investment = InvestmentEntity(
      id: widget.investment?.id ??
          'investment_${DateTime.now().microsecondsSinceEpoch}',
      memberId: _selectedMemberId,
      amount: amount,
      date: _selectedDate,
      description: _descriptionController.text.trim(),
    );

    Navigator.of(context).pop(investment);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Investment' : 'Add Investment',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedMemberId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Business Member',
              ),
              items: widget.members.map((member) {
                return DropdownMenuItem<String>(
                  value: member.id,
                  child: Text(
                    member.isActive
                        ? member.name
                        : '${member.name} (Inactive)',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedMemberId = value;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Investment Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Investment Date',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(_formatDate(_selectedDate)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. Initial business investment',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
