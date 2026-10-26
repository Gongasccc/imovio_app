import 'package:url_launcher/url_launcher.dart';

String _digits(String phone) => phone.replaceAll(RegExp(r'[^\d]'), '');

/// Números portugueses sem indicativo ganham o 351.
String internationalDigits(String phone) {
  final d = _digits(phone);
  return d.length == 9 ? '351$d' : d;
}

Future<bool> callPhone(String phone) =>
    launchUrl(Uri(scheme: 'tel', path: '+${internationalDigits(phone)}'));

/// Abre o WhatsApp com a conversa do número e, se houver, a mensagem escrita.
Future<bool> openWhatsApp(String phone, {String? text}) => launchUrl(
      Uri.https('wa.me', '/${internationalDigits(phone)}', {
        if (text != null && text.isNotEmpty) 'text': text,
      }),
      mode: LaunchMode.externalApplication,
    );

Future<bool> sendEmail(String email, {String? subject, String? body}) =>
    launchUrl(Uri(
      scheme: 'mailto',
      path: email,
      query: _query({'subject': subject, 'body': body}),
    ));

Future<bool> sendSms(String phone, {String? body}) => launchUrl(Uri(
      scheme: 'sms',
      path: '+${internationalDigits(phone)}',
      query: _query({'body': body}),
    ));

/// mailto e sms não aceitam "+" para espaços: codifica à mão.
String? _query(Map<String, String?> params) {
  final parts = [
    for (final e in params.entries)
      if (e.value != null && e.value!.isNotEmpty)
        '${e.key}=${Uri.encodeComponent(e.value!)}',
  ];
  return parts.isEmpty ? null : parts.join('&');
}

Future<bool> openExternalUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
