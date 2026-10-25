import 'package:url_launcher/url_launcher.dart';

String _digits(String phone) => phone.replaceAll(RegExp(r'[^\d]'), '');

/// Números portugueses sem indicativo ganham o 351.
String internationalDigits(String phone) {
  final d = _digits(phone);
  return d.length == 9 ? '351$d' : d;
}

Future<bool> callPhone(String phone) =>
    launchUrl(Uri(scheme: 'tel', path: '+${internationalDigits(phone)}'));

Future<bool> openWhatsApp(String phone) => launchUrl(
      Uri.parse('https://wa.me/${internationalDigits(phone)}'),
      mode: LaunchMode.externalApplication,
    );

Future<bool> sendEmail(String email) =>
    launchUrl(Uri(scheme: 'mailto', path: email));

Future<bool> openExternalUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
