# Razorpay Checkout SDK (https://razorpay.com/docs/payments/payment-gateway/android-integration/standard/)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
# Referenced by the Razorpay SDK but not used by BLOB.
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers
