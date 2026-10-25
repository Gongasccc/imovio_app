import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

String _norm(String? s) => (s ?? '')
    .toLowerCase()
    .replaceAll(RegExp('[áàâã]'), 'a')
    .replaceAll(RegExp('[éê]'), 'e')
    .replaceAll('í', 'i')
    .replaceAll(RegExp('[óôõ]'), 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ç', 'c')
    .trim();

bool _sameOrEmpty(String? wanted, String? actual) =>
    wanted == null || _norm(wanted) == _norm(actual);

/// Negócio que interessa a cada tipo de contacto. Vendedores não procuram.
String? _wantedNegocio(String contactType) => switch (contactType) {
      ContactTypes.buyer => 'Venda',
      ContactTypes.tenant => 'Arrendamento',
      _ => null,
    };

/// Imóveis compatíveis com as preferências do contacto. Um critério vazio
/// aceita qualquer valor. Imóveis vendidos ficam de fora.
List<Property> matchingProperties(Contact contact, List<Property> properties) {
  final prefs = contact.preferences;
  if (contact.type == ContactTypes.seller || prefs.isEmpty) return const [];
  final negocio = _wantedNegocio(contact.type);
  return properties.where((p) {
    if (p.saleStatus == 'Vendido') return false;
    if (negocio != null && p.negocio != null && p.negocio != negocio) {
      return false;
    }
    if (!_sameOrEmpty(prefs.distrito, p.distrito)) return false;
    if (!_sameOrEmpty(prefs.concelho, p.concelho)) return false;
    if (!_sameOrEmpty(prefs.tipo, p.tipo)) return false;
    if (!_sameOrEmpty(prefs.tipologia, p.tipologia)) return false;
    if (prefs.maxPrice != null &&
        (p.price == null || p.price! > prefs.maxPrice!)) {
      return false;
    }
    return true;
  }).toList();
}
