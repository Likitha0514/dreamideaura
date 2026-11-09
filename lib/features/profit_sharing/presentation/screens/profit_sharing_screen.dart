import 'package:flutter/material.dart';

import '../../../../core/storage/local_json_storage.dart';
import '../../../configuration/data/datasources/configuration_local_datasource.dart';
import '../../../configuration/data/repositories/configuration_repository_impl.dart';
import '../../../configuration/domain/entities/member_entity.dart';
import '../../../configuration/domain/entities/profit_configuration_entity.dart';
import '../../../configuration/domain/repositories/configuration_repository.dart';
import '../../../investment/data/datasources/investment_local_datasource.dart';
import '../../../investment/data/repositories/investment_repository_impl.dart';
import '../../../investment/domain/entities/investment_entity.dart';
import '../../../investment/domain/repositories/investment_repository.dart';
import '../../../products/data/datasources/product_local_datasource.dart';
import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/entities/member_product_earning.dart';
import '../../domain/entities/product_profit_result.dart';
import '../../domain/usecases/calculate_member_earnings.dart';
import '../../domain/usecases/calculate_product_profit.dart';

class ProfitSharingScreen extends StatefulWidget {
  const ProfitSharingScreen({super.key});

  @override
  State<ProfitSharingScreen> createState() => _ProfitSharingScreenState();
}

class _ProfitSharingScreenState extends State<ProfitSharingScreen> {
  late final ConfigurationRepository _configurationRepository;
  late final InvestmentRepository _investmentRepository;
  late final ProductRepository _productRepository;

  final CalculateProductProfit _calculateProductProfit =
      CalculateProductProfit();

  final CalculateMemberEarnings _calculateMemberEarnings =
      CalculateMemberEarnings();

  List<MemberEntity> _members = [];
  List<InvestmentEntity> _investments = [];
  List<ProductEntity> _products = [];

  ProfitConfigurationEntity _configuration =
      ProfitConfigurationEntity.defaults();

  Set<String> _selectedProductIds = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final storage = LocalJsonStorage();

    _configurationRepository = ConfigurationRepositoryImpl(
      ConfigurationLocalDataSource(storage),
    );

    _investmentRepository = InvestmentRepositoryImpl(
      InvestmentLocalDataSource(storage),
    );

    _productRepository = ProductRepositoryImpl(
      ProductLocalDataSource(storage),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _configurationRepository.getMembers(),
        _configurationRepository.getProfitConfiguration(),
        _investmentRepository.getInvestments(),
        _productRepository.getProducts(),
      ]);

      final members = results[0] as List<MemberEntity>;
      final configuration = results[1] as ProfitConfigurationEntity;
      final investments = results[2] as List<InvestmentEntity>;
      final products = results[3] as List<ProductEntity>;

      products.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;

      setState(() {
        _members = members;
        _configuration = configuration;
        _investments = investments;
        _products = products;
        _selectedProductIds = products.map((item) => item.id).toSet();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load profit sharing data: $error');
    }
  }

  List<ProductProfitResult> _getSelectedResults() {
    return _products
        .where((product) => _selectedProductIds.contains(product.id))
        .map(
          (product) => _calculateProductProfit(
            product: product,
            members: _members,
            investments: _investments,
            configuration: _configuration,
          ),
        )
        .toList();
  }

  List<MemberProductEarning> _getMemberEarnings(
    List<ProductProfitResult> results,
  ) {
    return _calculateMemberEarnings(
      productResults: results,
    );
  }

  double _sumResults(
    List<ProductProfitResult> results,
    double Function(ProductProfitResult) selector,
  ) {
    return results.fold<double>(
      0,
      (total, result) => total + selector(result),
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _selectAllProducts() {
    setState(() {
      _selectedProductIds = _products.map((item) => item.id).toSet();
    });
  }

  void _clearProductSelection() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  void _toggleProduct(String productId, bool selected) {
    setState(() {
      if (selected) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profit Sharing')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profit Sharing')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No products available.\nAdd products first to calculate profit sharing.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_configuration.isValid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profit Sharing')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Your profit percentages are invalid.\n'
              'Please update them in Configuration so the total equals 100%.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    List<ProductProfitResult> results;

    try {
      results = _getSelectedResults();
    } catch (error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profit Sharing')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to calculate profit sharing.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final memberEarnings = _getMemberEarnings(results);

    final totalSales = _sumResults(
      results,
      (result) => result.sellingPrice,
    );

    final totalDistributed = _sumResults(
      results,
      (result) => result.totalDistributed,
    );

    final totalInvestorPool = _sumResults(
      results,
      (result) => result.investorPool,
    );

    final totalEffortPool = _sumResults(
      results,
      (result) => result.effortPool,
    );

    final totalMarketingPool = _sumResults(
      results,
      (result) => result.marketingPool,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Sharing'),
        actions: [
          IconButton(
            onPressed: _loadData,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildPercentageCard(),
            const SizedBox(height: 16),
            _buildProductSelectionCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(
              totalSales: totalSales,
              totalDistributed: totalDistributed,
              investorPool: totalInvestorPool,
              effortPool: totalEffortPool,
              marketingPool: totalMarketingPool,
            ),
            const SizedBox(height: 24),
            const Text(
              'Member-wise Earnings',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (memberEarnings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No member earnings for the selected products.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...memberEarnings.map(_buildMemberEarningCard),
            const SizedBox(height: 24),
            const Text(
              'Product-wise Distribution',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Select at least one product to see its distribution.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...results.map(_buildProductResultCard),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profit Allocation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            _buildPercentageRow(
              'Investors',
              _configuration.investorPercentage,
            ),
            const SizedBox(height: 10),
            _buildPercentageRow(
              'Effort',
              _configuration.effortPercentage,
            ),
            const SizedBox(height: 10),
            _buildPercentageRow(
              'Marketing',
              _configuration.marketingPercentage,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_configuration.totalPercentage.toStringAsFixed(2)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageRow(String title, double percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          '${percentage.toStringAsFixed(2)}%',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProductSelectionCard() {
    final allSelected =
        _selectedProductIds.length == _products.length;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        title: const Text(
          'Select Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_selectedProductIds.length} of ${_products.length} selected',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Row(
            children: [
              TextButton(
                onPressed: _selectAllProducts,
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: _clearProductSelection,
                child: const Text('Clear All'),
              ),
              const Spacer(),
              if (allSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          ..._products.map((product) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _selectedProductIds.contains(product.id),
              title: Text(product.name),
              subtitle: Text(_formatCurrency(product.sellingPrice)),
              onChanged: (selected) {
                _toggleProduct(product.id, selected ?? false);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalSales,
    required double totalDistributed,
    required double investorPool,
    required double effortPool,
    required double marketingPool,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribution Summary',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Total Selling Value', totalSales),
            _buildSummaryRow('Total Distributed', totalDistributed),
            const Divider(height: 24),
            _buildSummaryRow('Investor Allocation', investorPool),
            _buildSummaryRow('Effort Allocation', effortPool),
            _buildSummaryRow('Marketing Allocation', marketingPool),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title)),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberEarningCard(MemberProductEarning earning) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          earning.memberName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total Earnings: ${_formatCurrency(earning.totalShare)}',
          style: const TextStyle(
            color: Color(0xFF9B6DFF),
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _buildSummaryRow(
            'Investor Earnings',
            earning.investorShare,
          ),
          _buildSummaryRow(
            'Effort Earnings',
            earning.effortShare,
          ),
          _buildSummaryRow(
            'Marketing Earnings',
            earning.marketingShare,
          ),
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Product-wise Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ..._getSelectedResults().map((result) {
            final matchingEarnings = result.memberEarnings.where(
              (item) => item.memberId == earning.memberId,
            );

            if (matchingEarnings.isEmpty) {
              return const SizedBox.shrink();
            }

            final item = matchingEarnings.first;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(result.productName)),
                  Text(
                    _formatCurrency(item.totalShare),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductResultCard(ProductProfitResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          result.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Selling Price: ${_formatCurrency(result.sellingPrice)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _buildSummaryRow('Investor Pool', result.investorPool),
          _buildSummaryRow('Effort Pool', result.effortPool),
          _buildSummaryRow('Marketing Pool', result.marketingPool),
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Member Distribution',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...result.memberEarnings.map((earning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          earning.memberName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatCurrency(earning.totalShare),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Investor: ${_formatCurrency(earning.investorShare)}'
                    '  |  Effort: ${_formatCurrency(earning.effortShare)}'
                    '  |  Marketing: ${_formatCurrency(earning.marketingShare)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          _buildSummaryRow(
            'Total Distributed',
            result.totalDistributed,
          ),
        ],
      ),
    );
  }
}