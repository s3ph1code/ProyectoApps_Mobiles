import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/community_category.dart';
import '../repositories/community_repository.dart';

class GetCommunityCategories
    implements UseCase<List<CommunityCategory>, NoParams> {
  final CommunityRepository repository;

  GetCommunityCategories(this.repository);

  @override
  Future<Either<Failure, List<CommunityCategory>>> call(NoParams params) {
    return repository.getCategories();
  }
}
