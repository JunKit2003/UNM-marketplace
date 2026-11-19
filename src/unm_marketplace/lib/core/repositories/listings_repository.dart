import 'package:dio/dio.dart';

import '../api/api_error.dart';
import '../api/models.dart';

/// Browse filters, kept in the page URL so a view can be shared.
class BrowseFilters {
  const BrowseFilters({this.q, this.categorySlug, this.condition, this.min, this.max, this.sort = 'newest'});

  final String? q;
  final String? categorySlug;
  final String? condition;
  final num? min;
  final num? max;
  final String sort;

  static const sorts = {'newest': 'Newest', 'price_asc': 'Price low to high', 'price_desc': 'Price high to low'};

  bool get isEmpty => (q ?? '').isEmpty && categorySlug == null && condition == null && min == null && max == null;
  int get activeFilterCount => [condition, min, max].where((v) => v != null).length;

  /// Query parameters for both the API and the page URL (defaults omitted).
  Map<String, String> toQuery() => {
        if ((q ?? '').isNotEmpty) 'q': q!,
        'category': ?categorySlug,
        'condition': ?condition,
        if (min != null) 'min': _n(min!),
        if (max != null) 'max': _n(max!),
        if (sort != 'newest') 'sort': sort,
      };

  static String _n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  factory BrowseFilters.fromQuery(Map<String, String> q) => BrowseFilters(
        q: q['q'],
        categorySlug: q['category'],
        condition: conditions.contains(q['condition']) ? q['condition'] : null,
        min: num.tryParse(q['min'] ?? ''),
        max: num.tryParse(q['max'] ?? ''),
        sort: sorts.containsKey(q['sort']) ? q['sort']! : 'newest',
      );

  BrowseFilters copyWith({
    Object? q = _keep,
    Object? categorySlug = _keep,
    Object? condition = _keep,
    Object? min = _keep,
    Object? max = _keep,
    String? sort,
  }) =>
      BrowseFilters(
        q: q == _keep ? this.q : q as String?,
        categorySlug: categorySlug == _keep ? this.categorySlug : categorySlug as String?,
        condition: condition == _keep ? this.condition : condition as String?,
        min: min == _keep ? this.min : min as num?,
        max: max == _keep ? this.max : max as num?,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is BrowseFilters && other.toQuery().toString() == toQuery().toString();

  @override
  int get hashCode => toQuery().toString().hashCode;
}

const _keep = Object();

class ListingDraft {
  const ListingDraft({
    required this.title,
    required this.description,
    required this.price,
    required this.categorySlug,
    required this.condition,
  });
  final String title, description, price, categorySlug, condition;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'price': price,
        'categorySlug': categorySlug,
        'condition': condition,
      };
}

class ListingsRepository {
  ListingsRepository(this._dio);
  final Dio _dio;

  Listing _one(Response r) => Listing.fromJson(r.data as Map<String, dynamic>);
  List<Listing> _many(Response r) => [for (final j in r.data as List) Listing.fromJson(j as Map<String, dynamic>)];

  List<MapEntry<String, MultipartFile>> _files(List<PickedPhoto> photos) => [
        for (final p in photos) MapEntry('photos', MultipartFile.fromBytes(p.bytes, filename: p.name)),
      ];

  Future<List<Category>> categories() => guard(() async {
        final r = await _dio.get('/categories');
        return [for (final j in r.data as List) Category.fromJson(j as Map<String, dynamic>)];
      });

  Future<PageResult<Listing>> search(BrowseFilters f, {int page = 1}) => guard(() async {
        final r = await _dio.get('/listings', queryParameters: {...f.toQuery(), 'page': '$page'});
        return PageResult.fromJson(r.data as Map<String, dynamic>, Listing.fromJson);
      });

  Future<Listing> get(int id) => guard(() async => _one(await _dio.get('/listings/$id')));

  Future<Listing> create(ListingDraft draft, List<PickedPhoto> photos) => guard(() async {
        final form = FormData.fromMap(draft.toJson());
        form.files.addAll(_files(photos));
        return _one(await _dio.post('/listings', data: form));
      });

  Future<Listing> update(int id, Map<String, dynamic> fields) =>
      guard(() async => _one(await _dio.patch('/listings/$id', data: fields)));

  Future<void> delete(int id) => guard(() => _dio.delete('/listings/$id'));

  Future<Listing> addImages(int id, List<PickedPhoto> photos) => guard(() async {
        final form = FormData()..files.addAll(_files(photos));
        return _one(await _dio.post('/listings/$id/images', data: form));
      });

  Future<Listing> deleteImage(int id, int imageId) =>
      guard(() async => _one(await _dio.delete('/listings/$id/images/$imageId')));

  Future<Listing> reorderImages(int id, List<int> imageIds) =>
      guard(() async => _one(await _dio.put('/listings/$id/images/order', data: {'imageIds': imageIds})));

  Future<List<Listing>> mine({String? status}) =>
      guard(() async => _many(await _dio.get('/me/listings', queryParameters: {'status': ?status})));

  Future<List<Listing>> saved() => guard(() async => _many(await _dio.get('/me/saved')));

  Future<void> save(int id) => guard(() => _dio.put('/listings/$id/save'));

  Future<void> unsave(int id) => guard(() => _dio.delete('/listings/$id/save'));
}
