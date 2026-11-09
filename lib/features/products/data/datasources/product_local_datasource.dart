import '../../../../core/storage/local_json_storage.dart';
import '../models/product_model.dart';

class ProductLocalDataSource {
  ProductLocalDataSource(this._storage);

  final LocalJsonStorage _storage;

  static const String _productsKey = 'products';

  Future<List<ProductModel>> getProducts() async {
    final data = await _storage.readData();

    final rawProducts = data[_productsKey] as List<dynamic>? ?? [];

    return rawProducts.map((item) {
      return ProductModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  Future<void> saveProducts(List<ProductModel> products) async {
    final data = await _storage.readData();

    data[_productsKey] =
        products.map((product) => product.toJson()).toList();

    await _storage.writeData(data);
  }
}