import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._dataSource);

  final ProductLocalDataSource _dataSource;

  @override
  Future<List<ProductEntity>> getProducts() async {
    return _dataSource.getProducts();
  }

  @override
  Future<void> addProduct(ProductEntity product) async {
    final products = await _dataSource.getProducts();

    if (products.any((item) => item.id == product.id)) {
      throw Exception('Product already exists.');
    }

    products.add(ProductModel.fromEntity(product));

    await _dataSource.saveProducts(products);
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    final products = await _dataSource.getProducts();

    final index = products.indexWhere(
      (item) => item.id == product.id,
    );

    if (index == -1) {
      throw Exception('Product not found.');
    }

    products[index] = ProductModel.fromEntity(product);

    await _dataSource.saveProducts(products);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final products = await _dataSource.getProducts();

    products.removeWhere(
      (item) => item.id == productId,
    );

    await _dataSource.saveProducts(products);
  }
}