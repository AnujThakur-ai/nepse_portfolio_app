import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_profile.dart';
import '../providers/app_providers.dart';
import '../services/company_repository.dart';
import '../services/company_search_service.dart';
import '../widgets/glass_panel.dart';
import 'technical_analysis_view.dart';
import 'trade_logger_view.dart';

class CompanySearchView extends ConsumerStatefulWidget {
  const CompanySearchView({super.key});

  @override
  ConsumerState<CompanySearchView> createState() => _CompanySearchViewState();
}

class _CompanySearchViewState extends ConsumerState<CompanySearchView> {
  final _searchController = TextEditingController();
  String _selectedSector = 'ALL';
  List<CompanyProfile> _filteredList = CompanyRepository.initialCompanies;
  String? _intentLabel;

  @override
  void initState() {
    super.initState();
    _filterCompanies();
  }

  void _filterCompanies() {
    final query = _searchController.text.trim();
    final result = CompanySearchService.search(
      query,
      watchlist: ref.read(watchlistProvider).toSet(),
    );
    var list = result.companies;
    if (_selectedSector != 'ALL') {
      list = list.where((c) => c.sector == _selectedSector).toList();
    }
    setState(() {
      _filteredList = list;
      _intentLabel = result.intentLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchlist = ref.watch(watchlistProvider);

    final sectors = [
      'ALL',
      ...CompanyRepository.initialCompanies.map((c) => c.sector).toSet(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('NEPSE Symbol Screener')),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Try “bullish banks” or “hydro watchlist”',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCompanies();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _filterCompanies(),
            ),
          ),

          if (_intentLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.auto_awesome, size: 15),
                  label: Text('Search intent: $_intentLabel'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

          // Sector Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: sectors.map((s) {
                final isSelected = _selectedSector == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedSector = s);
                      _filterCompanies();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Search Results
          Expanded(
            child: _filteredList.isEmpty
                ? const Center(
                    child: Text(
                      'No matching NEPSE companies found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final company = _filteredList[index];
                      final isWatchlisted = watchlist.contains(company.symbol);
                      final isBull = company.isBullish;
                      final trendColor = isBull
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444);

                      return GlassPanel(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showCompanyDetailModal(company, theme),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Symbol Box
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      26,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withAlpha(51),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      company.symbol,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Company & Sector
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        company.companyName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${company.sector} • P/E: ${company.peRatio}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface
                                              .withAlpha(153),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Circuit: [Rs ${company.lowerCircuitLimit} - ${company.upperCircuitLimit}]',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Price & Change
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rs ${company.ltp.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isBull ? '+' : ''}${company.percentageChange.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: trendColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        isWatchlisted
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: isWatchlisted
                                            ? Colors.amber
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(watchlistProvider.notifier)
                                            .toggleSymbol(company.symbol);
                                      },
                                    ),
                                  ],
                                ),
                              ],
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
  }

  void _showCompanyDetailModal(CompanyProfile c, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.symbol,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(c.companyName, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(
                    'Rs ${c.ltp}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'OFFLINE COMPANY DIRECTORY • NEPAL / NEPSE',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                c.description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(179),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Key Financial Ratios Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricTile('EPS (NPR)', c.eps.toStringAsFixed(2)),
                  _buildMetricTile('P/E Ratio', c.peRatio.toStringAsFixed(1)),
                  _buildMetricTile('Book Value', 'Rs ${c.bookValue}'),
                  _buildMetricTile('P/B Ratio', c.pbRatio.toStringAsFixed(2)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricTile('52W High', 'Rs ${c.fiftyTwoWeekHigh}'),
                  _buildMetricTile('52W Low', 'Rs ${c.fiftyTwoWeekLow}'),
                  _buildMetricTile('Market Cap', c.marketCap),
                  _buildMetricTile('Daily Volume', '${c.volume}'),
                ],
              ),
              const SizedBox(height: 14),

              // Circuit Breakers Info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(51),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '10% Circuit Limits (Today):',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Rs ${c.lowerCircuitLimit} - Rs ${c.upperCircuitLimit}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TechnicalAnalysisView(initialSymbol: c.symbol),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text('Technical Radar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TradeLoggerView(preselectedSymbol: c.symbol),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Log Trade'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
