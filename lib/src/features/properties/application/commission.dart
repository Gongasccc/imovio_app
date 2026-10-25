/// Valor da comissão a partir do preço e da percentagem, arredondado ao
/// cêntimo. Devolve null se faltar algum dos valores.
num? commissionValue({num? price, num? percent}) {
  if (price == null || percent == null || price <= 0 || percent <= 0) {
    return null;
  }
  return (price * percent / 100 * 100).round() / 100;
}
