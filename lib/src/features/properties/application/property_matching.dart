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

/// Lista vazia aceita qualquer valor; senão o valor tem de estar na lista.
bool _anyOf(List<String> wanted, String? actual) =>
    wanted.isEmpty || wanted.any((w) => _norm(w) == _norm(actual));

/// Negócios do imóvel aceites por cada negócio pedido pelo contacto.
const _negocioMap = {
  'Comprar': 'Venda',
  'Permuta': 'Venda',
  'Trespassar': 'Venda',
  'Arrendar': 'Arrendamento',
};

/// Palavras procuradas nas características do imóvel para cada comodidade.
const _extraWords = {
  'Garagem Box': ['box', 'garagem'],
  'Lugar de Garagem': ['garagem', 'estacionamento'],
  'Estacionamento Exterior': ['estacionamento'],
  'Varanda': ['varanda'],
  'Terraço': ['terraço', 'terraco'],
  'Quintal / Jardim': ['jardim', 'quintal'],
  'Pátio': ['pátio', 'patio'],
  'Com Elevador': ['elevador'],
  'Acesso Mobilidade Reduzida': ['mobilidade', 'acessível', 'rampa'],
  'Ar Condicionado': ['ar condicionado'],
  'Aquecimento Central': ['aquecimento central'],
  'Lareira': ['lareira', 'recuperador'],
  'Piscina Privada': ['piscina'],
  'Piscina Comum': ['piscina'],
  'Ginásio': ['ginásio', 'ginasio'],
  'Campo de Ténis': ['ténis', 'tenis'],
};

/// Negócios do imóvel aceites para o contacto: os escolhidos na ficha, ou o
/// tipo de contacto (comprador → venda, arrendatário → arrendamento).
Set<String> _wantedNegocios(Contact contact) {
  final chosen = contact.preferences.negocios
      .map((n) => _negocioMap[n])
      .whereType<String>()
      .toSet();
  if (chosen.isNotEmpty) return chosen;
  return switch (contact.type) {
    ContactTypes.buyer => {'Venda'},
    ContactTypes.tenant => {'Arrendamento'},
    _ => {},
  };
}

/// Quem só quer vender não procura imóveis.
bool _isSearching(Contact contact) {
  final n = contact.preferences.negocios;
  if (n.isNotEmpty) return n.any(_negocioMap.containsKey);
  return contact.type != ContactTypes.seller;
}

/// Um imóvel compatível e quantas comodidades pedidas tem.
class PropertyMatch {
  const PropertyMatch(this.property, this.extrasMatched, this.extrasWanted);
  final Property property;
  final int extrasMatched;
  final int extrasWanted;
}

/// Imóveis compatíveis com o que o contacto procura, os que têm mais das
/// comodidades pedidas primeiro. Critérios obrigatórios: negócio, tipo,
/// tipologia, zona, preço, área e casas de banho. As comodidades (exterior,
/// estacionamento, climatização...) só ordenam, porque muitos anúncios não
/// as indicam. Imóveis vendidos ficam de fora.
List<PropertyMatch> rankMatchingProperties(
  Contact contact,
  List<Property> properties,
) {
  final p = contact.preferences;
  if (p.isEmpty || !_isSearching(contact)) return const [];
  final negocios = _wantedNegocios(contact);
  final minWc = p.minWc;
  final matches = <PropertyMatch>[];
  for (final prop in properties) {
    if (prop.isSold) continue;
    if (negocios.isNotEmpty &&
        prop.negocio != null &&
        !negocios.contains(prop.negocio)) {
      continue;
    }
    if (!_anyOf(p.tipos, prop.tipo)) continue;
    if (!_anyOf(p.tipologias, prop.tipologia)) continue;
    if (!_anyOf(p.distritos, prop.distrito)) continue;
    if (!_anyOf(p.concelhos, prop.concelho)) continue;
    if (!_anyOf(p.freguesias, prop.freguesia)) continue;
    if (p.bairros.isNotEmpty && !_anyOf(p.bairros, prop.bairro)) continue;
    final price = prop.price;
    if (p.maxPrice != null && (price == null || price > p.maxPrice!)) continue;
    if (p.minPrice != null && (price == null || price < p.minPrice!)) continue;
    final area = prop.areaUtil ?? prop.areaBruta;
    if (p.minArea != null && (area == null || area < p.minArea!)) continue;
    if (p.maxArea != null && area != null && area > p.maxArea!) continue;
    if (minWc != null && prop.wc != null && prop.wc! < minWc) continue;

    final text = _norm('${prop.caracteristicas ?? ''} ${prop.desc ?? ''}');
    final extras = p.extras;
    final hit = extras
        .where(
            (e) => (_extraWords[e] ?? [e]).any((w) => text.contains(_norm(w))))
        .length;
    matches.add(PropertyMatch(prop, hit, extras.length));
  }
  matches.sort((a, b) => b.extrasMatched.compareTo(a.extrasMatched));
  return matches;
}

/// Atalho para quando só interessam os imóveis.
List<Property> matchingProperties(Contact contact, List<Property> properties) =>
    rankMatchingProperties(contact, properties).map((m) => m.property).toList();
