import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doan_local/components/header_section.dart';
import 'package:doan_local/theme/theme_manager.dart';
import 'package:doan_local/models/scan_result.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doan_local/main.dart';
import 'package:doan_local/models/filter_model.dart';



class PCBHistoryTab extends StatefulWidget {
  final Color surfaceCard;
  final Color errorRed;
  final Color primaryBlue;
  final Color textColor;
  final bool isDarkMode;

  const PCBHistoryTab({super.key, required this.surfaceCard, required this.errorRed, required this.primaryBlue, required this.textColor, required this.isDarkMode});

  @override
  State<PCBHistoryTab> createState() => _PCBHistoryTabState();

}

class _PCBHistoryTabState extends State<PCBHistoryTab> {
  int? _selectedStatus;
  DateTimeRange? _selectedDateRange;
  List<String> _availableFaultClasses = [];
  List<String> _selectedFaults = [];
  String selectedFilter = "Tất cả";
  List<ScanResult> _historyList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<ScanResult> _searchResults = [];
  bool _isSearching = false;

  final Map<String, String> faultDisplayMap = {
    "short": "Short",
    "spurious_copper": "Spurious Copper",
    "missing_hole": "Missing Hole",
    "spur": "Spur",
    "open_circuit": "Open Circuit",
    "mouse_bite": "Mouse Bite",
  };

  @override
  void initState() {
    super.initState();
    _fetchFaultClasses();
    _fetchHistory("Tất cả");
  }

  //hàm gọi api lấy danh sách lỗi cho bộ lọc
  Future<void> _fetchFaultClasses() async {
    try {
      final response = await dio.get('/api/fault-classes');
      setState(() {
        _availableFaultClasses = (response.data as List).map((i) => i.toString()).toList();
      });
    } catch (e) {
      debugPrint("Lỗi tải danh sách lỗi: $e");
    }
  }

  Future<List<String>> _fetchSuggestions(String query) async {
    try {
      final response = await dio.get('/api/search/suggestions', queryParameters: {'q': query});
      return (response.data as List).map((i) => i.toString()).toList();
    } catch (e) { return []; }
  }


  Future<void> _fetchHistoryWithFilters() async {
    setState(() => _isLoading = true);

    final filter = FilterModel(
      faultClasses: _selectedFaults,
      status: _selectedStatus,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );

    try {
      // Không cần set headers thủ công ở đây nữa
      final response = await dio.post(
        '/api/filter',
        data: filter.toJson(),
      );

      setState(() {
        _historyList = (response.data as List).map((i) => ScanResult.fromJson(i)).toList();
      });
    } catch (e) {
      debugPrint("Lỗi tải lịch sử: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHistory(String? query) async {
    setState(() => _isLoading = true);
    try {
      final searchQuery = (query == null || query == "Tất cả") ? "" : query;

      debugPrint("Đang tìm kiếm với query: $query");
      final response = await dio.get('/api/search',
          queryParameters: {'q': searchQuery}
      );
      debugPrint("Response data: ${response.data}");

      setState(() {
        _historyList = (response.data as List).map((i) => ScanResult.fromJson(i)).toList();
      });
    } catch (e) {
      debugPrint("Lỗi tải lịch sử: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      endDrawer: _buildFilterDrawer(),
      body: ValueListenableBuilder<bool>(
        valueListenable: ThemeService.isDarkModeNotifier,
        builder: (context, isDarkMode, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(
                  title: "Lịch sử quét lỗi",
                  textColor: widget.textColor,
                  isDarkMode: isDarkMode,
                  onThemeChanged: (val) => ThemeService.isDarkModeNotifier.value = val,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (val) => val.text.isEmpty
                            ? const Iterable.empty()
                            : _fetchSuggestions(val.text),
                        onSelected: (String selection) => _fetchHistory(selection),
                        fieldViewBuilder: (ctx, controller, focusNode, onSub) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: TextStyle(color: widget.textColor),
                            decoration: InputDecoration(
                              hintText: "Gõ loại lỗi...",
                              hintStyle: TextStyle(color: widget.textColor.withOpacity(0.5)),
                              filled: true,
                              fillColor: widget.surfaceCard,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none
                              ),
                            ),
                            onSubmitted: (value) => _fetchHistory(value),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút mở Drawer lọc
                    Builder(
                      builder: (innerContext) => IconButton(
                        onPressed: () => Scaffold.of(innerContext).openEndDrawer(),
                        icon: Icon(Icons.filter_list_rounded, color: widget.primaryBlue),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                //_buildFilterChips(),
                const SizedBox(height: 10),
                _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : (_searchController.text.isNotEmpty ? _buildSearchResults() : _buildRecentScansList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      backgroundColor: widget.surfaceCard,
      width: 300,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bộ lọc nâng cao",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.textColor)),
              Divider(color: widget.textColor.withOpacity(0.2)),

              ListTile(
                textColor: widget.textColor,
                iconColor: widget.textColor,
                title: const Text("Khoảng thời gian"),
                subtitle: Text(
                  _selectedDateRange == null
                      ? "Chọn ngày..."
                      : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                  style: TextStyle(color: widget.textColor.withOpacity(0.5)),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2027),
                    initialDateRange: _selectedDateRange,
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData(
                          useMaterial3: true,
                          colorScheme: ColorScheme.dark(
                            primary: widget.primaryBlue,
                            onPrimary: Colors.white,
                            surface: widget.surfaceCard,
                            onSurface: widget.textColor,
                          ),
                          scaffoldBackgroundColor: widget.surfaceCard,
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(foregroundColor: widget.primaryBlue),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() => _selectedDateRange = picked);
                  }
                },
              ),

              const SizedBox(height: 20),

              Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.w600, color: widget.textColor)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatusChip("Đạt", 1),
                  const SizedBox(width: 8),
                  _buildStatusChip("Không đạt", 0),
                ],
              ),
              const SizedBox(height: 20),

              Text("Loại lỗi", style: TextStyle(fontWeight: FontWeight.w600, color: widget.textColor)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableFaultClasses.map((label) {
                  final displayName = faultDisplayMap[label] ?? label;
                  final isSelected = _selectedFaults.contains(label);
                  return FilterChip(
                    label: Text(displayName, style: TextStyle(color: isSelected ? Colors.white : widget.textColor)),
                    backgroundColor: widget.surfaceCard.withOpacity(0.5),
                    selectedColor: widget.primaryBlue,
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedFaults.add(label);
                        } else {
                          _selectedFaults.remove(label);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Gọi API tìm kiếm với các filter đã chọn
                    _fetchHistoryWithFilters();
                    debugPrint("Lọc theo: $_selectedFaults, Ngày: $_selectedDateRange");
                    Navigator.pop(context);
                    // Gọi hàm fetch với params filter ở đây
                    // _fetchHistoryWithFilters(_selectedFaults, _selectedDateRange);
                  },
                  child: const Text("Áp dụng bộ lọc"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatusChip(String label, int value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : widget.textColor)),
      selected: isSelected,
      selectedColor: widget.primaryBlue,
      backgroundColor: widget.surfaceCard.withOpacity(0.5),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : null;
        });
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text("Không tìm thấy kết quả",
            style: TextStyle(color: widget.textColor.withOpacity(0.5))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return Card(
          color: widget.surfaceCard,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.originalImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text("PCB_BATCH_${item.id}",
                style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
            trailing: Text(
              item.isPassed == 0 ? "Lỗi: ${item.faultCount}" : "Đạt",
              style: TextStyle(
                color: item.isPassed == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _buildFilterChips() {
  //   final Map<String, String> _filterMap = {
  //     "Tất cả": "Tất cả",
  //     "Missing Hole": "missing_hole",
  //     "Mouse Bite": "mouse_bite",
  //     "Open Circuit": "open_circuit",
  //     "Spur": "spur",
  //     "Spurious Copper": "spurious_copper",
  //     "Short Circuit": "short"
  //   };
  //   final displayFilters = _filterMap.keys.toList();
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       SizedBox(
  //         height: 38,
  //         child: ListView.separated(
  //           scrollDirection: Axis.horizontal,
  //           itemCount: displayFilters.length,
  //           separatorBuilder: (context, index) => const SizedBox(width: 8),
  //           itemBuilder: (context, index) {
  //             final display = displayFilters[index];
  //             final apiValue = _filterMap[display];
  //             final isSelected = display == selectedFilter;
  //
  //             return GestureDetector(
  //               onTap: () {
  //                 setState(() => selectedFilter = display);
  //                 _fetchHistory(apiValue!);
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                 decoration: BoxDecoration(
  //                   color: isSelected ? widget.primaryBlue : widget.surfaceCard,
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: Center(
  //                   child: Text(
  //                     display,
  //                     style: TextStyle(
  //                       color: isSelected ? Colors.white : widget.textColor,
  //                       fontSize: 13,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildRecentScansList() {
    if (_historyList.isEmpty) return Center(child: Text("Không có lịch sử quét", style: TextStyle(color: widget.textColor.withOpacity(0.5))));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _historyList[index];
        final date = DateTime.parse(item.createdAt).toLocal();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: widget.surfaceCard,
              borderRadius: BorderRadius.circular(12)
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.originalImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[800]),
                  errorWidget: (context, url, error) => Icon(Icons.broken_image),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "PCB_BATCH_${item.id}",
                        style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),

                    Text(

                        "Quét lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(date)}",
                        style: TextStyle(color: widget.textColor.withOpacity(0.5), fontSize: 11)
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (item.faultCount == 0 ? Colors.green : Colors.redAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.faultCount == 0 ? "Đạt" : "Lỗi: ${item.faultCount}",
                  style: TextStyle(
                    color: item.faultCount == 0 ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}