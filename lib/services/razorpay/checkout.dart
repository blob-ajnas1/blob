// Picks the Razorpay Checkout implementation for the current platform:
// the native SDK on Android/iOS, checkout.js on the web.
export 'checkout_types.dart';
export 'checkout_unsupported.dart'
    if (dart.library.io) 'checkout_mobile.dart'
    if (dart.library.js_interop) 'checkout_web.dart';
