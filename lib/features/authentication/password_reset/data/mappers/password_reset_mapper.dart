import '../../domain/entities/password_reset_result.dart';
import '../models/password_reset_response_model.dart';

abstract final class PasswordResetMapper {
  static PasswordResetResult toDomain(PasswordResetResponseModel model) {
    return PasswordResetResult(message: model.message);
  }
}
