import '../../domain/entities/email_verification_result.dart';
import '../models/email_verification_response_model.dart';

abstract final class EmailVerificationMapper {
  static EmailVerificationResult toDomain(
    EmailVerificationResponseModel model,
  ) {
    return EmailVerificationResult(message: model.message);
  }
}
