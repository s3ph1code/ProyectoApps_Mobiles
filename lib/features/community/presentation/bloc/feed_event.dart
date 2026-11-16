import 'package:equatable/equatable.dart';

sealed class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial y reintento: categorías y primera página.
class FeedRequested extends FeedEvent {
  const FeedRequested();
}

/// Filtra por categoría y vuelve a la primera página. `null` es «Todas».
class FeedCategorySelected extends FeedEvent {
  final String? categoryId;

  const FeedCategorySelected(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// La usuaria llegó al final de la lista.
class FeedNextPageRequested extends FeedEvent {
  const FeedNextPageRequested();
}

/// Vuelve a traer la primera página con el filtro actual.
class FeedRefreshed extends FeedEvent {
  const FeedRefreshed();
}
