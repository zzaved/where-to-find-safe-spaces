/// User-facing browsing categories, mapped to the backend's `category` values.
enum PlaceCategory {
  all('all', 'Todos'),
  restaurant('restaurant', 'Restaurantes'),
  cafe('cafe', 'Cafés'),
  bar('bar', 'Bares'),
  nightClub('night_club', 'Baladas'),
  gym('gym', 'Academias'),
  store('store', 'Lojas'),
  hotel('hotel', 'Hotéis');

  const PlaceCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
