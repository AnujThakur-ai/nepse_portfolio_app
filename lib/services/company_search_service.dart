import '../models/company_profile.dart';
import 'company_repository.dart';

/// Lightweight offline intent parsing for company search.
/// This improves query matching but is not a BERT language model.
class CompanySearchResult {
  final List<CompanyProfile> companies;
  final String? intentLabel;

  const CompanySearchResult({required this.companies, this.intentLabel});
}

class CompanySearchService {
  static const _sectorIntents = <String, List<String>>{
    'Banks': ['bank', 'banks', 'banking', 'financial', 'finance'],
    'Hydropower': ['hydro', 'hydropower', 'power', 'electricity'],
    'Insurance': ['insurance', 'insurer', 'insurers'],
    'Hotels': ['hotel', 'hotels', 'hospitality'],
    'Microfinance': ['microfinance', 'micro', 'laghubitta'],
  };

  static const _fillerWords = {
    'show',
    'find',
    'search',
    'me',
    'the',
    'a',
    'an',
    'for',
    'in',
    'with',
    'companies',
    'company',
    'stocks',
    'stock',
    'shares',
    'share',
    'of',
    'my',
    'please',
    'all',
    'top',
    'best',
    'performing',
    'performers',
  };

  static CompanySearchResult search(
    String input, {
    Set<String> watchlist = const {},
  }) {
    final query = input.toLowerCase().trim();
    if (query.isEmpty) {
      return CompanySearchResult(companies: CompanyRepository.allCompanies);
    }

    final words =
        query.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').split(RegExp(r'\s+'))
          ..removeWhere((word) => word.isEmpty || _fillerWords.contains(word));
    String? sectorIntent;
    for (final entry in _sectorIntents.entries) {
      if (entry.value.any(words.contains)) {
        sectorIntent = entry.key;
        break;
      }
    }

    final bullish = words.any(
      const {
        'bullish',
        'bull',
        'strong',
        'positive',
        'gainer',
        'gainers',
        'up',
        'rising',
        'green',
      }.contains,
    );
    final bearish = words.any(
      const {
        'bearish',
        'bear',
        'weak',
        'negative',
        'loser',
        'losers',
        'down',
        'falling',
        'fallers',
        'red',
      }.contains,
    );
    final onlyWatchlist = words.any(
      const {'watchlist', 'starred', 'saved'}.contains,
    );
    final intentWords = <String>{
      ..._sectorIntents.values.expand((values) => values),
      'bullish',
      'bull',
      'strong',
      'positive',
      'gainer',
      'gainers',
      'up',
      'rising',
      'green',
      'bearish',
      'bear',
      'weak',
      'negative',
      'loser',
      'losers',
      'down',
      'falling',
      'fallers',
      'red',
      'watchlist',
      'starred',
      'saved',
    };
    final terms = words.where((word) => !intentWords.contains(word)).toList();

    final scored = <(CompanyProfile, int)>[];
    for (final company in CompanyRepository.allCompanies) {
      if (sectorIntent != null &&
          !company.sector.toLowerCase().contains(
            sectorIntent
                .toLowerCase()
                .replaceAll('hydropower', 'hydro')
                .replaceAll('hotels', 'hotel')
                .replaceAll('microfinance', 'micro'),
          )) {
        continue;
      }
      if ((bullish && !company.isBullish) || (bearish && company.isBullish)) {
        continue;
      }
      if (onlyWatchlist && !watchlist.contains(company.symbol)) continue;

      final fields = [
        company.symbol,
        company.companyName,
        company.sector,
        company.description,
      ].map((field) => field.toLowerCase()).toList();
      var score = 0;
      var matchesAll = true;
      for (final term in terms) {
        var termScore = 0;
        if (fields[0] == term) {
          termScore = 12;
        } else if (fields[0].contains(term)) {
          termScore = 9;
        } else if (fields[1].contains(term)) {
          termScore = 6;
        } else if (fields[2].contains(term)) {
          termScore = 5;
        } else if (fields[3].contains(term)) {
          termScore = 2;
        }
        if (termScore == 0) matchesAll = false;
        score += termScore;
      }
      if (matchesAll) scored.add((company, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final labels = <String>[];
    if (sectorIntent != null) labels.add(sectorIntent);
    if (bullish) labels.add('Bullish movers');
    if (bearish) labels.add('Bearish movers');
    if (onlyWatchlist) labels.add('Watchlist');
    return CompanySearchResult(
      companies: scored.map((entry) => entry.$1).toList(),
      intentLabel: labels.isEmpty ? null : labels.join(' · '),
    );
  }
}
