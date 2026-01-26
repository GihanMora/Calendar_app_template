import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    try {
      // Ad Unit ID is read from config/country_x.json (single source of truth)
      _nativeAd = NativeAd(
        adUnitId: AppConfig.nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
                _hasError = false;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted) {
              setState(() {
                _nativeAd = null;
                _isAdLoaded = false;
                _hasError = true;
              });
            }
            print('Native ad failed to load: $error');
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Colors.white,
          cornerRadius: 10.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.blue,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.grey,
            style: NativeTemplateFontStyle.normal,
            size: 14.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.grey,
            style: NativeTemplateFontStyle.normal,
            size: 12.0,
          ),
        ),
      );
      _nativeAd!.load();
    } catch (e) {
      print('Error creating native ad: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isAdLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    // Don't show anything if ad failed or not loaded yet
    if (_hasError || !_isAdLoaded || _nativeAd == null) {
      return const SizedBox(height: 0, width: double.infinity);
    }

    try {
      final color = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        key: const ValueKey('native_ad_container'),
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          minHeight: 0,
          maxHeight: 400,
        ),
        decoration: BoxDecoration(
          color: isDark ? color.surfaceVariant : color.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.outlineVariant,
            width: 1,
          ),
        ),
        child: Builder(
          builder: (context) {
            try {
              return AdWidget(ad: _nativeAd!);
            } catch (e, stackTrace) {
              print('Error rendering AdWidget: $e');
              print('Stack trace: $stackTrace');
              return const SizedBox(height: 0, width: double.infinity);
            }
          },
        ),
      );
    } catch (e, stackTrace) {
      print('Error building native ad widget: $e');
      print('Stack trace: $stackTrace');
      return const SizedBox(height: 0, width: double.infinity);
    }
  }
}
