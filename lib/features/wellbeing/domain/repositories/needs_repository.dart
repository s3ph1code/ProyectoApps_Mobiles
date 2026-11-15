import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/need_option.dart';
import '../entities/recommendation.dart';

abstract class NeedsRepository {
  /// Las opciones activas que se le ofrecen a la usuaria.
  Future<Either<Failure, List<NeedOption>>> getNeedOptions();

  /// Las sugerencias para [optionIds], de mayor a menor relevancia.
  Future<Either<Failure, List<Recommendation>>> getRecommendations({
    required List<String> optionIds,
  });

  /// Deja la consulta en el historial y devuelve el id de la sesión.
  Future<Either<Failure, String>> saveNeedSession({
    required String userId,
    required List<String> optionIds,
  });
}
