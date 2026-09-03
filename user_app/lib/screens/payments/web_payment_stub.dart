void launchRazorpayWebCheckoutHelper({
  required String keyId,
  required String orderId,
  required int amountInPaise,
  required String productName,
  required String userEmail,
  required String userPhone,
  required Function(String paymentId, String orderId, String signature) onSuccess,
  required Function(String errorMsg) onError,
}) {
  // No-op on non-web platforms (Android/iOS/Desktop)
}
