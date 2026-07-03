import '../core/network/api_client.dart';
import '../models/hierarchy_model.dart';
import '../core/constants/api_constants.dart';

class HierarchyRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<HierarchyNodeModel>> getUserHierarchy({int? depth}) async {
    final Map<String, String> queryParams = {};
    if (depth != null) {
      queryParams['depth'] = depth.toString();
    }
    
    final response = await _apiClient.get(
      ApiConstants.hierarchy,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    
    final list = response['data'] as List? ?? [];
    return list.map((json) => HierarchyNodeModel.fromJson(json)).toList();
  }
}
