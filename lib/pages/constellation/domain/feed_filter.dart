enum FeedFilter { all, dawn, morning, day, evening, night }

const Set<String> allowedFeedFilters = <String>{
  'all',
  'dawn',
  'morning',
  'day',
  'evening',
  'night',
};

FeedFilter parseFeedFilter(String? raw) {
  final String normalized = raw?.trim().toLowerCase() ?? 'all';
  switch (normalized) {
    case 'dawn':
      return FeedFilter.dawn;
    case 'morning':
      return FeedFilter.morning;
    case 'day':
      return FeedFilter.day;
    case 'evening':
      return FeedFilter.evening;
    case 'night':
      return FeedFilter.night;
    case 'all':
    default:
      return FeedFilter.all;
  }
}

String feedFilterToName(FeedFilter filter) {
  switch (filter) {
    case FeedFilter.dawn:
      return 'dawn';
    case FeedFilter.morning:
      return 'morning';
    case FeedFilter.day:
      return 'day';
    case FeedFilter.evening:
      return 'evening';
    case FeedFilter.night:
      return 'night';
    case FeedFilter.all:
      return 'all';
  }
}
