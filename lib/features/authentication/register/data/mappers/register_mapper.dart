import '../../domain/entities/register_result.dart';
import '../models/register_response_model.dart';

abstract final class RegisterMapper {
  static RegisterResult toDomain(RegisterResponseModel model) {
    return RegisterResult(message: model.message);
  }
}
