import 'package:doan_local/services/dio_instances.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doan_local/theme/theme_manager.dart';
import 'package:doan_local/models/scan_result.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doan_local/models/filter_model.dart';


class PCBHistoryTab extends StatefulWidget {
  final Color surfaceCard;
  final Color errorRed;
  final Color primaryBlue;
  final Color textColor;
  final bool isDarkMode;

  const PCBHistoryTab({
    super.key,
    required this.surfaceCard,
    required this.errorRed,
    required this.primaryBlue,
    required this.textColor,
    required this.isDarkMode,
  });

  @override
  State<PCBHistoryTab> createState() => _PCBHistoryTabState();
}

class _PCBHistoryTabState extends State<PCBHistoryTab> {
  int? _selectedStatus;
  DateTimeRange? _selectedDateRange;
  List<String> _availableFaultClasses = [];
  List<String> _selectedFaults = [];
  List<ScanResult> _historyList = [];
  List<ScanResult> _searchResults = [];

  bool _isLoading = true;
  bool _isSearching = false;
  bool _isFiltering = false;

  TextEditingController _searchController = TextEditingController();

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

  Future<void> _fetchFaultClasses() async {
    try {
      final response = await DioClient.deviceDio.get('/fault-classes');
      setState(() {
        _availableFaultClasses = (response.data as List).map((i) => i.toString()).toList();
      });
    } catch (e) {
      debugPrint("Lỗi tải danh sách lỗi: $e");
    }
  }

  Future<List<String>> _fetchSuggestions(String query) async {

    try {
      debugPrint("--- ĐANG GỌI REQUEST ---");
      debugPrint("Headers: ${DioClient.deviceDio.options.headers}");

      final response = await DioClient.deviceDio.get('/search/suggestions', queryParameters: {'q': query});
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

      final response = await DioClient.deviceDio.post('/filter', data: filter.toJson());
      setState(() {
        List<ScanResult> results = (response.data as List).map((i) => ScanResult.fromJson(i)).toList();
        _searchResults = results;
        _isFiltering = true;
        _searchController.clear();
      });
    } catch (e) {
      debugPrint("Lỗi tải lịch sử: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHistory(String? query) async {
    setState(() {
      _isLoading = true;
      _isSearching = true;
      _isFiltering = false;
    });
    try {
      final searchQuery = (query == null || query == "Tất cả") ? "" : query;
      final response = await DioClient.deviceDio.get('/search', queryParameters: {'q': searchQuery});

      setState(() {
        List<ScanResult> results = (response.data as List).map((i) => ScanResult.fromJson(i)).toList();
        _historyList = results;
        _searchResults = results;
        _searchController.text = searchQuery;
      });
    } catch (e) {
      debugPrint("Lỗi tải lịch sử: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isSearching = false;
      });
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
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        displayStringForOption: (option) => faultDisplayMap[option] ?? option,
                        optionsBuilder: (val) => val.text.isEmpty
                            ? const Iterable.empty()
                            : _fetchSuggestions(val.text),
                        onSelected: (String selection) {
                          _fetchHistory(selection);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _searchController.text = faultDisplayMap[selection] ?? selection;
                          });
                        },
                        fieldViewBuilder: (ctx, controller, focusNode, onSub) {
                          _searchController = controller;
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (value) {
                              String code = faultDisplayMap.entries.firstWhere(
                                      (e) => e.value.toLowerCase() == value.toLowerCase(),
                                  orElse: () => MapEntry(value, value)).key;
                              _fetchHistory(code);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (innerContext) => IconButton(
                        onPressed: () => Scaffold.of(innerContext).openEndDrawer(),
                        icon: Icon(Icons.filter_list_rounded, color: widget.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const SizedBox(height: 10),
                _isSearching || _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_isFiltering || _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : _buildRecentScansList()),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bộ lọc nâng cao", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.textColor)),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text("Xóa", style: TextStyle(color: widget.errorRed)),
                  ),
                ],
              ),
              Divider(color: widget.textColor.withOpacity(0.2)),
              ListTile(
                textColor: widget.textColor,
                iconColor: widget.textColor,
                title: const Text("Khoảng thời gian"),
                subtitle: Text(
                  _selectedDateRange == null ? "Chọn ngày..." : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                  style: TextStyle(color: widget.textColor.withOpacity(0.5)),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2027),
                    initialDateRange: _selectedDateRange,
                    builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: widget.primaryBlue)), child: child!),
                  );
                  if (picked != null) setState(() => _selectedDateRange = picked);
                },
              ),
              const SizedBox(height: 20),
              Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.w600, color: widget.textColor)),
              const SizedBox(height: 10),
              Row(children: [_buildStatusChip("Đạt", 1), const SizedBox(width: 8), _buildStatusChip("Không đạt", 0)]),
              const SizedBox(height: 20),
              Text("Loại lỗi", style: TextStyle(fontWeight: FontWeight.w600, color: widget.textColor)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 4,
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
                        if (selected) _selectedFaults.add(label); else _selectedFaults.remove(label);
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: widget.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () {
                    _fetchHistoryWithFilters();
                    Navigator.pop(context);
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

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDateRange = null;
      _selectedFaults = [];
      _isFiltering = false;
      _searchController.clear();
    });
    _fetchHistory("Tất cả");
  }

  Widget _buildStatusChip(String label, int value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : widget.textColor)),
      selected: isSelected,
      selectedColor: widget.primaryBlue,
      backgroundColor: widget.surfaceCard.withOpacity(0.5),
      onSelected: (selected) {
        setState(() => _selectedStatus = selected ? value : null);
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(child: Text("Không tìm thấy kết quả", style: TextStyle(color: widget.textColor.withOpacity(0.5))));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final date = DateTime.tryParse(item.createdAt)?.toLocal();
        bool isError = item.faultCount > 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: widget.surfaceCard, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: item.originalImage, width: 50, height: 50, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PCB_BATCH_${item.id}", style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(date != null ? "Quét lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(date)}" : "N/A", style: TextStyle(color: widget.textColor.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: (isError ? Colors.redAccent : Colors.green).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(isError ? "Lỗi: ${item.faultCount}" : "Đạt", style: TextStyle(color: isError ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

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
        bool isError = item.faultCount > 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: widget.surfaceCard, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: item.originalImage, width: 50, height: 50, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PCB_BATCH_${item.id}", style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Quét lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(date)}", style: TextStyle(color: widget.textColor.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: (isError ? Colors.redAccent : Colors.green).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(isError ? "Lỗi: ${item.faultCount}" : "Đạt", style: TextStyle(color: isError ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}