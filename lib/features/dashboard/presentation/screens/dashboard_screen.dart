import 'package:flutter/material.dart';

import '../../../../core/storage/local_json_storage.dart';
import '../../../configuration/data/datasources/configuration_local_datasource.dart';
import '../../../configuration/data/repositories/configuration_repository_impl.dart';
import '../../../configuration/domain/entities/member_entity.dart';
import '../../../configuration/domain/repositories/configuration_repository.dart';
import '../../../configuration/presentation/screens/configuration_screen.dart';
import '../../../investment/data/datasources/investment_local_datasource.dart';
import '../../../investment/data/repositories/investment_repository_impl.dart';
import '../../../investment/domain/entities/investment_entity.dart';
import '../../../investment/domain/repositories/investment_repository.dart';
import '../../../investment/presentation/screens/investment_screen.dart';
import '../../../products/data/datasources/product_local_datasource.dart';
import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../backup_restore/presentation/screens/backup_restore_screen.dart';
import '../../../profit_sharing/presentation/screens/profit_sharing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ConfigurationRepository _configurationRepository;
  late final InvestmentRepository _investmentRepository;
  late final ProductRepository _productRepository;

  List<MemberEntity> _members = [];
  List<InvestmentEntity> _investments = [];
  List<ProductEntity> _products = [];

  bool _isLoading = true;
  String? _errorMessage;

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

    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        _configurationRepository.getMembers(),
        _investmentRepository.getInvestments(),
        _productRepository.getProducts(),
      ]);

      if (!mounted) return;

      setState(() {
        _members = results[0] as List<MemberEntity>;
        _investments = results[1] as List<InvestmentEntity>;
        _products = results[2] as List<ProductEntity>;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load dashboard data.';
      });
    }
  }

  int get _activeMemberCount =>
      _members.where((member) => member.isActive).length;

  double get _totalInvestment => _investments.fold<double>(
        0,
        (total, investment) => total + investment.amount,
      );

  double get _totalSellingValue => _products.fold<double>(
        0,
        (total, product) => total + product.sellingPrice,
      );

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Future<void> _openScreen(Widget screen) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute<bool>(
      builder: (context) => screen,
    ),
  );

  if (!mounted) return;

  await _loadDashboard();

  if (result == true && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App data updated successfully.'),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DreamsIdeAura',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Business Overview'),
                      const SizedBox(height: 12),
                      _buildSummaryGrid(),
                      const SizedBox(height: 28),
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 12),
                      _buildQuickActions(),
                      const SizedBox(height: 28),
                      _buildRecentProducts(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9B6DFF),
            Color(0xFFC77DFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'DreamsIdeAura ✨',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your creativity, investments and earnings in one place.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildSummaryCard(
          title: 'Active Members',
          value: '$_activeMemberCount',
          icon: Icons.people_outline,
          color: const Color(0xFF9B6DFF),
        ),
        _buildSummaryCard(
          title: 'Total Investment',
          value: _formatCurrency(_totalInvestment),
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF00A896),
        ),
        _buildSummaryCard(
          title: 'Total Products',
          value: '${_products.length}',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFFFF9F43),
        ),
        _buildSummaryCard(
          title: 'Selling Value',
          value: _formatCurrency(_totalSellingValue),
          icon: Icons.currency_rupee,
          color: const Color(0xFFE56B9F),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionTile(
          title: 'Configuration',
          subtitle: 'Manage members and profit percentages',
          icon: Icons.settings_outlined,
          color: const Color(0xFF9B6DFF),
          onTap: () => _openScreen(const ConfigurationScreen()),
        ),
        _buildActionTile(
          title: 'Investment',
          subtitle: 'Add and manage member investments',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF00A896),
          onTap: () => _openScreen(const InvestmentScreen()),
        ),
        _buildActionTile(
          title: 'Products',
          subtitle: 'Manage products and contributors',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFFFF9F43),
          onTap: () => _openScreen(const ProductsScreen()),
        ),
        _buildActionTile(
          title: 'Profit Sharing',
          subtitle: 'View member-wise earnings and distribution',
          icon: Icons.pie_chart_outline,
          color: const Color(0xFFE56B9F),
          onTap: () => _openScreen(const ProfitSharingScreen()),
        ),
        _buildActionTile(
  title: 'Backup & Restore',
  subtitle: 'Save, restore or reset your business data',
  icon: Icons.backup_outlined,
  color: const Color(0xFF6C63FF),
  onTap: () => _openScreen( BackupRestoreScreen()),
),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentProducts() {
    final recentProducts = _products.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Recent Products'),
            TextButton(
              onPressed: () => _openScreen(const ProductsScreen()),
              child: const Text('View All'),
            ),
          ],
        ),
        if (recentProducts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No products added yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ...recentProducts.map((product) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF1E9FF),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF9B6DFF),
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${product.date.day.toString().padLeft(2, '0')}/'
                  '${product.date.month.toString().padLeft(2, '0')}/'
                  '${product.date.year}',
                ),
                trailing: Text(
                  _formatCurrency(product.sellingPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadDashboard();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}