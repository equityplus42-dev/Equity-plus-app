import 'dart:js_util' as js_util;
import 'dart:js' as js;

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
  try {
    js_util.callMethod(
      js_util.globalThis,
      'launchRazorpayCheckout',
      [
        keyId,
        orderId,
        amountInPaise,
        productName,
        'Vridhi Network Membership',
        userEmail,
        userPhone,
        js.allowInterop((paymentId, returnedOrderId, signature) {
          onSuccess(paymentId?.toString() ?? '', returnedOrderId?.toString() ?? orderId, signature?.toString() ?? '');
        }),
        js.allowInterop((errorMsg) {
          onError(errorMsg?.toString() ?? 'Payment cancelled.');
        }),
      ],
    );
  } catch (err) {
    onError(err.toString());
  }
}
