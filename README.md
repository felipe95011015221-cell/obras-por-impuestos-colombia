# Obras por Impuestos Colombia

Investigación sobre la ejecución de proyectos del mecanismo **Obras por Impuestos (OxI)** en Colombia: qué ministerios responden por cada sector, qué proyectos se aprobaron entre 2018 y 2025, qué hay en trámite en 2026, cómo van las obras y cuáles tienen el plazo vencido.

Los datos vienen de fuentes públicas oficiales (Agencia de Renovación del Territorio y Departamento Nacional de Planeación) y se limpiaron con los scripts de este repositorio.

**Tablero integrado OxI, Regalías y CoCrea (2020–2026):** compara los tres mecanismos con un mismo estado, en su propio repositorio: [Tablero-Proyectos-COCREA-REGALIAS-OXI](https://github.com/felipe95011015221-cell/Tablero-Proyectos-COCREA-REGALIAS-OXI). Página: <https://felipe95011015221-cell.github.io/Tablero-Proyectos-COCREA-REGALIAS-OXI/>.

**Tablero de Obras por Impuestos (este repositorio):**

- En GitHub Pages: <https://felipe95011015221-cell.github.io/obras-por-impuestos-colombia/>
- En Claude: [Obras por Impuestos Colombia](https://claude.ai/artifact/SRSXDXked8Pk5ugWk4Rd3t). Es privado hasta que su dueño lo comparte desde el menú Compartir.

## Hallazgos principales

| Tema | Resultado |
|---|---|
| Proyectos aprobados 2018–2025 | 527 proyectos por $4,07 billones, en 291 municipios, con 311 empresas contribuyentes |
| Sector con más recursos | Educación, con 241 proyectos |
| Proyectos en trámite (corte 3 jul 2026) | 557 proyectos por $5,21 billones de costo estimado |
| Trámite devuelto con observaciones | 334 de 557 (60 %); MinEnergía devuelve el 84 % y MinEducación el 71 % |
| Cartera financiable frente al cupo 2026 | $1,43 billones registrados, 1,25 veces el cupo del CONFIS ($1,145 billones) |
| Municipios nuevos en el mecanismo | 64, sin proyectos aprobados antes |
| Obras terminadas según el DNP | 69 con avance físico de 99 % o más |
| Proyectos con plazo vencido | 145 por $0,96 billones; 43 en alerta crítica ($249 mil millones) |

## Contenido

```
index.html             Tablero como página independiente (la que publica GitHub Pages)
web/dash.js            Carga los datos y dibuja los gráficos fuera de Claude
web/tokens.css         Colores, tipografía y espacios, en azules y blanco
tablero/index.html     Tablero para el tipo Dashboard de Claude (secciones, gráficos y cálculos)
tablero/estilos.css    Estilos del tablero
datos/                 Datos limpios en JSON que usa el tablero
fuentes/               Archivos originales descargados de la ART y respuestas del DNP
scripts/               Scripts en Ruby para regenerar los datos y la página
```

### Ver el tablero

- **En GitHub Pages:** en el repositorio, Settings → Pages → Build and deployment → Source: "Deploy from a branch", rama `main`, carpeta `/ (root)`. En uno o dos minutos queda en la dirección de arriba.
- **En tu computador:** el navegador no carga los datos si abres `index.html` con doble clic. Sirve la carpeta con un servidor local, por ejemplo `ruby -run -e httpd . -p 8000` o `python3 -m http.server 8000`, y abre <http://localhost:8000>.
- **Si cambias el tablero:** edita `tablero/index.html` o `tablero/estilos.css` y vuelve a generar la página con `ruby -Ku scripts/armar_pagina_web.rb`.

### Datos

| Archivo | Qué contiene | Fuente |
|---|---|---|
| `datos/ministerios.json` | 13 entidades nacionales competentes, su sector y su respaldo (decreto, datos ART o por verificar) | Decreto 1625/2016 (mod. Decreto 647/2018), Decreto 1147/2020, bases de la ART |
| `datos/proyectos.json` | 527 proyectos aprobados 2018–2025 con año, modalidad, valor, sector, ministerio, municipio y empresa | ART, base de resultados (preliminar, sep 2026) |
| `datos/tramite.json` | 557 proyectos en trámite con fase, proponente, línea, costo y estado SUIFP | ART, listado en prefactibilidad y factibilidad (corte 3 jul 2026) |
| `datos/cruce_municipios.json` | 372 municipios con lo aprobado frente a lo que está en trámite | Cruce propio de las dos bases anteriores |
| `datos/ejecucion.json` | Estado, avance físico y pagos de cada proyecto aprobado | MapaInversiones del DNP (corte 1 nov 2026) |
| `datos/vencidos.json` | 145 proyectos con plazo vencido, avance de productos y nivel de alerta | MapaInversiones del DNP |
| `datos/cupos.json`, `datos/indicadores.json`, `datos/educacion_*.json` | Cupos CONFIS y cifras publicadas en prensa y comunicados | Forbes, Semana, Portafolio, El Espectador, MinEducación, MinTransporte |

### Fuentes oficiales

- ART, resultados de Obras por Impuestos: <https://www.renovacionterritorio.gov.co/obras-por-impuestos/resultados-obras-por-impuestos>
- ART, página del mecanismo (listado de proyectos en trámite): <https://www.renovacionterritorio.gov.co/obras-por-impuestos>
- ART, Banco de Proyectos: <https://obrasporimpuestos.renovacionterritorio.gov.co>
- DNP, MapaInversiones: <https://mapainversiones.dnp.gov.co>

## Cómo regenerar los datos

Los scripts usan solo la librería estándar de Ruby (probados con Ruby 2.6). Desde la raíz del repositorio:

```bash
# 1. Base de aprobados: descomprimir el Excel y convertirlo a filas
mkdir -p /tmp/oxi_x && unzip -o -q fuentes/art/base-resultados-2018-2026-preliminar.xlsx -d /tmp/oxi_x
ruby -Ku scripts/xlsx_a_json.rb /tmp/oxi_x > /tmp/crudo.json
ruby -Ku scripts/limpiar_proyectos.rb /tmp/crudo.json datos/proyectos.json

# 2. Listado en trámite
mkdir -p /tmp/oxi_t && unzip -o -q fuentes/art/tramite-2026-07-03.xlsx -d /tmp/oxi_t
ruby -Ku scripts/xlsx_a_json.rb /tmp/oxi_t > /tmp/tramite_crudo.json
ruby -Ku scripts/limpiar_tramite.rb /tmp/tramite_crudo.json datos/tramite.json

# 3. Cruce por municipio
ruby -Ku scripts/cruce_municipios.rb datos/proyectos.json datos/tramite.json datos/cruce_municipios.json

# 4. Ejecución (consulta el DNP; tarda unos 3 minutos)
ruby -Ku scripts/descargar_mapainversiones.rb datos/proyectos.json fuentes/dnp/mapainversiones_fichas.json
ruby -Ku scripts/armar_ejecucion.rb datos/proyectos.json fuentes/dnp/mapainversiones_fichas.json datos/ejecucion.json

# 5. Revisión de vencidos (consulta los productos de cada vencido en el DNP)
ruby -Ku scripts/revisar_vencidos.rb datos/ejecucion.json fuentes/dnp/productos_vencidos.json datos/vencidos.json
```

## Método

- **Ministerio competente:** se asigna por la línea de inversión de cada proyecto. Para Gestión del riesgo (UNGRD) y Pagos por servicios ambientales o Adaptación al cambio climático (MinAmbiente) la entidad es una suposición sin confirmar. Infraestructura productiva queda "Por definir".
- **Cruce por municipio:** une por nombre de municipio y departamento, sin tildes. Un proyecto de varios municipios cuenta en cada uno y su valor se reparte por partes iguales. Los 4 proyectos aprobados de varios departamentos no entran en el cruce.
- **Situación de ejecución:** combina el estado del proyecto en el SUIFP con su avance físico. "Terminada" es avance físico de 99 % o más.
- **Plazo vencido:** proyecto en ejecución, con avance físico menor a 99 % y horizonte terminado antes de 2026.
- **Pagos:** se usan solo cuando lo pagado no supera el valor del proyecto. En 94 proyectos el DNP reporta pagos mayores al valor, que parecen cifras agregadas del programa de la ART.
- **Niveles de alerta de los vencidos:**
  - Crítica: ningún avance físico ni de productos y horizonte terminado en 2024 o antes.
  - Alta: avance menor a 50 %, o ninguno con horizonte terminado en 2025.
  - Pagada, sin avance reportado: pagos de la mitad o más del valor sin avance cargado.
  - Media: avance de 50 % o más sin terminar.

## Limitaciones

- La base de aprobados de la ART es preliminar y trae el valor aprobado, no el avance de obra.
- "Sin avance reportado" no quiere decir que la obra no haya empezado: en la opción fiducia la obra la ejecuta el contribuyente y su avance no siempre se carga en el sistema del DNP.
- Una alerta crítica es una señal para pedir información, no una prueba de incumplimiento: el plazo pudo ampliarse sin actualizarse en la ficha.
- Ningún BPIN de los proyectos vencidos aparece en los contratos del SECOP II. En fiducia la contratación la hace un patrimonio autónomo privado.
- El costo de los proyectos en trámite lo estima el proponente.
- El conteo de empresas se basa en los nombres tal como vienen en la base, sin unificar variantes.
- El portal de la fiducia (Fiduprevisora) no se pudo consultar por su protección contra accesos automáticos.
