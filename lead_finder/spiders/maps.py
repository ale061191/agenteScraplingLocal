from typing import List, Dict, Any, Optional
from lead_finder.models import Lead
from lead_finder.config import Settings
from lead_finder.address_utils import is_likely_address, extract_address_from_lines
import re


class MapsSpider:
    def __init__(self, settings: Settings):
        self.settings = settings

    def _search_url(self, category: str, location: str) -> str:
        q = f"{category} en {location}"
        return f"https://www.google.com/maps/search/{q.replace(' ', '+')}/"

    def search(self, category: str, location: str, deep: bool = False,
               max_deep: int = 5, state: Optional[str] = None,
               city: Optional[str] = None,
               parish: Optional[str] = None,
               sector: Optional[str] = None) -> List[Lead]:
        import sys
        print(f"  [MAPS DEBUG] Iniciando scraper...")
        print(f"  [MAPS DEBUG] Python: {sys.version}")
        try:
            import scrapling
            print(f"  [MAPS DEBUG] Scrapling version: {scrapling.__version__ if hasattr(scrapling, '__version__') else 'desconocida'}")
        except Exception as e:
            print(f"  [MAPS ERROR] No se pudo importar scrapling: {e}")
        from scrapling.engines._browsers._stealth import StealthySession

        url = self._search_url(category, location)
        captured: List[Dict[str, Any]] = []

try:
            with StealthySession(
                headless=self.settings.headless,
                locale="es-ES",
            ) as session:
                def action(page):
                    print(f"    [DEBUG] URL: {page.url}")
                    print(f"    [DEBUG] Titulo: {page.title()}")
                    page.wait_for_timeout(1000)
                    if "consent" in page.url.lower():
                        print("    [DEBUG] Detectado popup de consentimiento, intentando clic...")
                        try:
                            page.locator("button:has-text('Aceptar todo')").first.click(timeout=3000)
                            print("    [DEBUG] Clic en 'Aceptar todo' exitoso")
                        except Exception as e:
                            print(f"    [DEBUG] Boton 'Aceptar todo' no encontrado, intentando otro metodo: {e}")
                            try:
                                page.locator("button[id*='agree'], button[id*='accept'], #L2QgC",).first.click(timeout=3000)
                            except:
                                try:
                                    page.evaluate("""() => {
                                        const btns = document.querySelectorAll('button');
                                        for (const b of btns) {
                                            if (b.textContent.includes('Aceptar') || b.textContent.includes('Accept')) { b.click(); break; }
                                        }
                                    }""")
                                except: pass
                        page.wait_for_timeout(2000)
                        try:
                            page.wait_for_load_state("networkidle", timeout=8000)
                        except:
                            pass

                    print("    [DEBUG] Buscando feed de resultados...")
                    feed_exists = page.evaluate("""() => !!document.querySelector('[role="feed"]')""")
                    print(f"    [DEBUG] Feed existe: {feed_exists}")

                    if not feed_exists:
                        print("    [DEBUG] ADVERTENCIA: No se encontro feed de Google Maps!")
                        page.wait_for_timeout(3000)
                        print(f"    [DEBUG] URL actual: {page.url}")
                        print(f"    [DEBUG] Contenido body (primeros 500 chars): {page.evaluate('() => document.body ? document.body.innerText.substring(0,500) : \"vacio\"')}")

                    for i in range(self.settings.scroll_times):
                        page.evaluate("""() => {
                            const f = document.querySelector('[role="feed"]');
                            if (f) f.scrollBy(0, f.clientHeight || 500);
                            else window.scrollBy(0, window.innerHeight || 500);
                        }""")
                        page.wait_for_timeout(self.settings.scroll_delay_ms)

                    page.wait_for_timeout(400)

                    raw = page.evaluate("""() => {
                        const feed = document.querySelector('[role="feed"]');
                        if (!feed) {
                            // Intentar con selector alternativo
                            const alt = document.querySelector('.bfdHYA, [data-result-index], .Nv2PKb');
                            if (alt) {
                                const articles = document.querySelectorAll('.bfdHYA, [data-result-index], .Nv2PKb');
                                const results = [];
                                const seen = new Set();
                                articles.forEach(article => {
                                    if (seen.has(article)) return;
                                    seen.add(article);
                                    const name = article.querySelector('.fontBodyMedium, .qBF1Pd, [aria-label]')?.textContent?.trim() || '';
                                    if (!name || name.length < 2) return;
                                    results.push({ name, rating: null, reviews_count: null, address: '', phone: '', website: '', href: '' });
                                });
                                return results;
                            }
                            return [];
                        }
                        const articles = feed.querySelectorAll('div[role="article"]');
                        const results = [];
                        const seen = new Set();
                        articles.forEach(article => {
                            if (seen.has(article)) return;
                            seen.add(article);
                            let name = article.getAttribute('aria-label') || '';
                            if (!name || name.length < 2) {
                                const ne = article.querySelector('.fontHeadlineSmall, [role="heading"], h1, h2, h3');
                                if (ne) name = (ne.textContent || '').trim();
                            }
                            if (!name || name.length < 2) return;
                            let rating = null, reviews = null;
                            const re = article.querySelector('[role="img"][aria-label]');
                            if (re) {
                                const lbl = re.getAttribute('aria-label') || '';
                                const rm = lbl.match(/([\\d.,]+)/);
                                if (rm) rating = parseFloat(rm[1].replace(',', '.'));
                                const rvm = lbl.match(/\\((\\d+)\\s*/);
                                if (rvm) reviews = parseInt(rvm[1]);
                            }
                            let phone = '', website = '';
                            article.querySelectorAll('a[href]').forEach(a => {
                                const h = a.href || '';
                                if (h.startsWith('tel:')) phone = h.replace('tel:', '').split('?')[0];
                                else if (h.startsWith('http') && !h.includes('google.com/maps')
                                         && !h.includes('google.com/search') && !website) website = h;
                            });
                            const sections = article.querySelectorAll('.W4Efsd');
                            let address = '';
                            const allLines = [];
                            sections.forEach(sec => {
                                const txt = sec.textContent || '';
                                const lines = txt.split('\\n').map(s => s.trim()).filter(Boolean);
                                lines.forEach(l => allLines.push(l));
                            });
                            for (const line of allLines) {
                                if (line !== name && line.length > 5 && line.length < 300
                                    && !line.includes('�~.') && !line.includes('��')
                                    && !/^\\d+\\s*rese��/i.test(line) && !line.startsWith('http')
                                    && !line.includes('�"�') && !line.includes('$')
                                    && !line.includes('Cerrado') && !line.includes('Abierto')
                                    && !line.includes('horario') && !line.includes('accesible')
                                    && !/^[A-Z][a-z]+$/.test(line)
                                    && !/^(?:Lun|Mar|Mi[eǸ]|Jue|Vie|S[aǭ]b|Dom)/i.test(line)
                                    && !/^\\d{1,2}[.:]\\d{2}\\s*(?:a\\.?m\\.?|p\\.?m\\.?)?$/i.test(line)) {
                                    address = line; break;
                                }
                            }
                            if (!address) {
                                for (const line of allLines) {
                                    if (line !== name && line.length > 5 && line.length < 300
                                        && (line.includes('Calle') || line.includes('Av.') || line.includes('Avenida')
                                            || line.includes('Carretera') || line.includes('Urb.')
                                            || line.includes('Urbanizacion') || line.includes('Carrera')
                                            || line.includes('Edif.') || line.includes('Edificio')
                                            || line.includes('Centro Comercial') || line.includes('CC ')
                                            || line.includes('Local ') || line.includes('Sector ')
                                            || line.includes('Barrio ') || line.includes('Torre ')
                                            || line.includes('Km ') || line.includes('Esq.') || line.includes('Transversal')
                                            || line.includes('Via ') || line.includes('Boulevard')
                                            || line.match(/^[A-Z�?�%�?�"�s�'][a-zǭǸ����ǧ��]+\\s+\\d/))) {
                                        address = line; break;
                                    }
                                }
                            }
                            const link = article.querySelector('a[href*="/maps/place/"]');
                            const href = link ? link.href : '';
                            results.push({ name, rating, reviews_count: reviews, address, phone, website, href });
                        });
                        return results;
                    }""")
                    print(f"    [DEBUG] Elementos capturados por JS: {len(raw)}")
                    captured.extend(raw)

                print(f"  [MAPS] Navegando a: {url}")
                session.fetch(
                    url,
                    page_action=action,
                    load_dom=True,
                    network_idle=True,
                    timeout=600000,
                )
        except Exception as e:
            print(f"  [MAPS ERROR] Fallo en StealthySession: {e}")
            import traceback
            traceback.print_exc()
            return []

        leads = []

        leads = []
        for item in captured:
            lead = Lead(
                name=item.get("name", ""),
                category=category,
                location=location,
                state=state or None,
                city=city or None,
                address=item.get("address") or None,
                phone=item.get("phone") or None,
                website=item.get("website") or None,
                email=item.get("email") or None,
                facebook=item.get("facebook") or None,
                instagram=item.get("instagram") or None,
                twitter=item.get("twitter") or None,
                rating=item.get("rating"),
                reviews_count=item.get("reviews_count"),
                source="google_maps",
                source_url=url,
            )
            leads.append(lead)

        return leads
