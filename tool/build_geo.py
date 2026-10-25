"""Gera assets/geo/portugal.json (distritos > concelhos > freguesias) a partir
da GeoAPI.pt. Correr só quando a divisão administrativa mudar:

    python tool/build_geo.py
"""
import json
import urllib.request
from pathlib import Path

BASE = 'https://json.geoapi.pt'
ILHAS = {
    '31': 'Ilha da Madeira', '32': 'Ilha de Porto Santo',
    '41': 'Ilha de Santa Maria', '42': 'Ilha de São Miguel',
    '43': 'Ilha Terceira', '44': 'Ilha Graciosa', '45': 'Ilha de São Jorge',
    '46': 'Ilha do Pico', '47': 'Ilha do Faial', '48': 'Ilha das Flores',
    '49': 'Ilha do Corvo',
}


def get(path):
    with urllib.request.urlopen(f'{BASE}{path}', timeout=60) as r:
        return json.loads(r.read().decode('utf-8'))


def main():
    distritos = {d['codigoine']: d['distrito'] for d in get('/distritos')}
    for code, name in ILHAS.items():
        distritos.setdefault(code, name)
    out = {}
    for m in get('/municipios/freguesias'):
        code = m['codigoine'][:2]
        distrito = distritos.get(code)
        if distrito is None:
            continue
        out.setdefault(distrito, {})[m['nome']] = sorted(m.get('freguesias') or [])
    data = {
        'fonte': 'GeoAPI.pt (CAOP)',
        'distritos': {d: dict(sorted(c.items())) for d, c in sorted(out.items())},
    }
    path = Path(__file__).resolve().parent.parent / 'assets' / 'geo' / 'portugal.json'
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')),
                    encoding='utf-8')
    total = sum(len(c) for c in out.values())
    print(f'{len(out)} distritos, {total} concelhos -> {path}')


if __name__ == '__main__':
    main()
