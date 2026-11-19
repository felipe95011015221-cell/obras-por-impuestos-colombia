# encoding: utf-8
# Genera index.html (página independiente para GitHub Pages) a partir de tablero/index.html,
# que es la versión que corre dentro del tipo Dashboard de Claude.
# Uso, desde la raíz del repositorio: ruby -Ku scripts/armar_pagina_web.rb
cuerpo = File.read('tablero/index.html', encoding: 'UTF-8')
cuerpo = cuerpo.sub(/\A<meta name="dash-one-writer">\s*/, '').sub(/<link rel="stylesheet" href="estilos.css">\s*/, '')
pagina = <<~HTML
  <!doctype html>
  <html lang="es">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>Obras por Impuestos Colombia</title>
  <meta name="description" content="Tablero sobre la ejecución de proyectos de Obras por Impuestos en Colombia: ministerios, proyectos aprobados 2018–2025, trámite 2026, ejecución y plazos vencidos.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700&family=Source+Serif+4:opsz,wght@8..60,400&display=swap">
  <link rel="stylesheet" href="web/tokens.css">
  <link rel="stylesheet" href="tablero/estilos.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/7.9.0/d3.min.js"></script>
  <script src="web/dash.js" data-base="datos/"></script>
  </head>
  <body>
  <div id="dash-root">
  #{cuerpo.strip}
  <footer class="ox-pie">
    <p>Fuentes: Agencia de Renovación del Territorio (base de resultados 2018–2025 y listado de trámite con corte al 3 de julio de 2026) y MapaInversiones del DNP (corte 1 de noviembre de 2026). Cifras de prensa y comunicados en la tabla de cifras publicadas.</p>
    <p>Datos, método y limitaciones en el <a href="https://github.com/felipe95011015221-cell/obras-por-impuestos-colombia">repositorio del proyecto</a>.</p>
  </footer>
  </div>
  </body>
  </html>
HTML
File.write('index.html', pagina)
puts "index.html: #{pagina.bytesize} bytes"
