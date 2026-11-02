import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Un caso de uso hace una sola cosa y se invoca como función.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Caso de uso que emite valores a lo largo del tiempo, por ejemplo los
/// cambios de sesión.
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
