import re
from typing import Optional

ADDRESS_KEYWORDS = [
    r'Calle\s', r'Av\.?\s', r'Avenida\s', r'Carretera\s',
    r'Urb\.?\s', r'Urbanizacion\s', r'Urbanización\s',
    r'Carrera\s', r'Edif\.?\s', r'Edificio\s',
    r'Centro Comercial', r'CC\s',
    r'Local\s', r'Piso\s', r'PB\b', r'Sector\s',
    r'Barrio\s', r'Residencias\s', r'Conjunto\sResidencial',
    r'Torre\s', r'Esquina\s', r'Esq\.?\s',
    r'Transversal\s', r'Callejon\s', r'Callejón\s',
    r'Pasaje\s', r'Manzana\s', r'Vía\s', r'Via\s', r'Km\s',
    r'Avda\.?\s', r'Autopista\s',
    r'Final\s+(?:Av|Calle|Avenida)',
    r'Boulevard\s', r'Prolongacion\s', r'Prolongación\s',
]

ADDRESS_PATTERN = re.compile(
    '(?:' + '|'.join(ADDRESS_KEYWORDS) + r')[^\n]{3,120}',
    re.IGNORECASE
)

SHORT_ADDR_PATTERN = re.compile(
    r'(?:Nro\.?\s|No\.?\s|#' r'\s*)\d{1,5}',
    re.IGNORECASE
)

NON_ADDRESS_TEXTS = [
    '★', '·', 'http', 'reseña', 'reseñ', '€', '$',
    'Cerrado', 'Abierto', 'horario', 'accesible',
    'silla de ruedas', 'estacionamiento',
]


def is_likely_address(text: str, name: str = '') -> bool:
    t = text.strip()
    if not t or len(t) < 6 or len(t) > 250:
        return False
    if name and (t == name or name in t):
        return False
    for na in NON_ADDRESS_TEXTS:
        if na.lower() in t.lower():
            return False
    if ADDRESS_PATTERN.search(t):
        return True
    if re.search(r'\d{1,5}\s*,?\s*(?:Calle|Av\.|Avenida|Carrera)', t, re.IGNORECASE):
        return True
    if re.match(r'^[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+\s+\d', t):
        return True
    return False


def extract_address_from_lines(lines, name: str = '') -> Optional[str]:
    for line in lines:
        t = line.strip().rstrip(',.')
        if not t or len(t) < 6:
            continue
        if name and (t == name or t.startswith(name)):
            continue
        if is_likely_address(t, name):
            return t
    return None


def extract_address_from_text(text: str, name: str = '') -> Optional[str]:
    t = text.strip()
    if len(t) < 6 or len(t) > 300:
        return None
    if name and (t == name or name in t):
        return None
    for na in NON_ADDRESS_TEXTS:
        if na.lower() in t.lower():
            return None
    if ADDRESS_PATTERN.search(t):
        return t
    return None
