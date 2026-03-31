import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_core/app_config.dart';
import 'package:sint/sint.dart';

import '../utils/constants/app_assets.dart';
import '../utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import 'theme/app_color.dart';
import 'theme/app_theme.dart';

/// Displays Terms & Conditions from a bundled markdown asset file.
///
/// Each app has its own terms file in `neom_commons/assets/legal/`.
/// Placeholders `{{APP_NAME}}` and `{{CONTACT_EMAIL}}` are replaced
/// at runtime with the current app's values.
class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  String _content = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    try {

      final raw = await rootBundle.loadString(AppAssets.termsConditions);
      final appName = AppProperties.getAppName();
      final email = _getContactEmail();

      setState(() {
        _content = raw
            .replaceAll('{{APP_NAME}}', appName.isNotEmpty ? appName : 'App')
            .replaceAll('{{CONTACT_EMAIL}}', email);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _content = 'No se pudieron cargar los terminos de servicio.';
        _loading = false;
      });
    }
  }

  String _getContactEmail() {
    final app = AppConfig.instance.appInUse;
    switch (app) {
      case AppInUse.e:
        return 'contacto@emxi.org';
      case AppInUse.g:
        return 'contacto@gigmeout.com';
      case AppInUse.c:
        return 'contacto@cyberneom.xyz';
      case AppInUse.i:
        return 'contacto@itzli.mx';
      default:
        return AppProperties.getEmail().isNotEmpty
            ? AppProperties.getEmail()
            : 'contacto@neom.app';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          CommonTranslationConstants.termsAndConditions.tr,
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _buildMarkdownContent(),
                  ),
                ),
              ),
      ),
    );
  }

  /// Simple markdown-like renderer (no external package needed).
  Widget _buildMarkdownContent() {
    final lines = _content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(2),
            style: TextStyle(
              color: AppColor.bondiBlue,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            line.substring(3),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('  •  ', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line.replaceAll('**', ''),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
          ),
        ));
      } else {
        // Handle inline bold **text**
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildRichText(line),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Handles inline **bold** within a line.
  Widget _buildRichText(String text) {
    final spans = <InlineSpan>[];
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ));
    }

    if (spans.isEmpty) {
      return Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
