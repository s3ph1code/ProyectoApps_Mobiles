import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/managed_user.dart';
import '../repositories/role_admin_repository.dart';
import 'resolve_administrator.dart';

class SearchUsers implements UseCase<List<ManagedUser>, SearchUsersParams> {
  final ResolveAdministrator resolveAdministrator;
  final RoleAdminRepository repository;

  SearchUsers({required this.resolveAdministrator, required this.repository});

  static const minQueryLength = 2;

  @override
  Future<Either<Failure, List<ManagedUser>>> call(
    SearchUsersParams params,
  ) async {
    final query = params.query.trim();
    // Una sola letra devolvería casi a todo el mundo; vacío es «el equipo».
    if (query.isNotEmpty && query.length < minQueryLength) {
      return const Left(SearchTooShortFailure());
    }

    final access = await resolveAdministrator(const NoParams());
    return access.fold(
      (failure) => Left(failure),
      (_) => repository.searchUsers(query),
    );
  }
}

class SearchUsersParams extends Equatable {
  final String query;

  const SearchUsersParams({this.query = ''});

  @override
  List<Object?> get props => [query];
}
