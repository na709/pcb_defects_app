import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:doan_local/components/header_section.dart';
import 'package:doan_local/theme/theme_manager.dart';

class ScanResult {
  final int id;
  final String originalImage;
  final String createdAt;
  final int faultCount;
  final int isPassed;

  ScanResult({
    required this.id,
    required this.originalImage,
    required this.createdAt,
    required this.faultCount,
    required this.isPassed,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] ?? 0,
      originalImage: json['original_image'] ?? '',
      createdAt: json['created_at'] ?? '',
      faultCount: json['fault_count'] ?? 0,
      isPassed: json['is_passed'] ?? 0,
    );
  }
}

class SearchScreen extends StatefulWidget {
  final Color surfaceColor;
  final Color textColor;
  final bool isDarkMode;

  const SearchScreen({
    Key? key,
    required this.surfaceColor,
    required this.textColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.214:3000'));
  List<ScanResult> _results = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    //debugPrint("DEBUG: Bắt đầu tìm kiếm với từ khóa: $query");
    try {
      final response = await _dio.get(
        '/api/search',
        queryParameters: {'q': query},
        options: Options(headers: {'x-device-id': 'BE2A.250530.026.F3'}),
      );

      //debugPrint("DEBUG: Dữ liệu API trả về: ${response.data}");

      if (response.data is List) {
        setState(() {
          _results = (response.data as List).map((item) => ScanResult.fromJson(item)).toList();
        });
        debugPrint("DEBUG: Đã cập nhật _results với ${_results.length} phần tử");
      }
    } catch (e) {
      debugPrint("Lỗi search: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchSuggestions(String query) async {
    try {
      final response = await _dio.get('/api/search/suggestions', queryParameters: {'q': query});
      return (response.data as List).map((item) => item.toString()).toList();
    } catch (e) {
      debugPrint("Lỗi gợi ý: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              HeaderSection(
                title: "Tìm kiếm",
                textColor: widget.textColor,
                isDarkMode: isDarkMode,
                onThemeChanged: (val) {
                  ThemeService.isDarkModeNotifier.value = val;
                },
              ),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return await _fetchSuggestions(textEditingValue.text);
                },
                onSelected: (String selection) {
                  _performSearch(selection);
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: widget.textColor),
                      decoration: InputDecoration(
                        hintText: "Gõ loại lỗi...",
                        filled: true,
                        fillColor: widget.surfaceColor,
                        prefixIcon: Icon(Icons.search, color: widget.textColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (value) => _performSearch(value),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Material(
                        elevation: 4,
                        color: widget.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(option, style: TextStyle(color: widget.textColor)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_isLoading) const LinearProgressIndicator(),
              Expanded(
                child: _results.isEmpty
                    ? Center(child: Text("Không có dữ liệu", style: TextStyle(color: widget.textColor)))
                    : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return Card(
                      color: widget.surfaceColor,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                            "PCB_BATCH_${item.id}",
                            style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)
                        ),
                        subtitle: Text(
                            item.createdAt,
                            style: TextStyle(color: widget.textColor.withOpacity(0.6))
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.textColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Lỗi: ${item.faultCount}",
                            style: TextStyle(
                                color: item.faultCount > 0 ? Colors.redAccent : Colors.green,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}