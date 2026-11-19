# encoding: utf-8
# Cruza proyectos aprobados (2018-2025) y en trámite (2026) por municipio.
# Proyectos de varios municipios: cuentan en cada uno y su valor se reparte por partes iguales.
# Proyectos de varios departamentos se excluyen (no se puede saber a qué departamento va cada municipio).
require 'json'
apr = JSON.parse(File.read(ARGV[0], encoding: 'UTF-8'))
tra = JSON.parse(File.read(ARGV[1], encoding: 'UTF-8'))
def norm(s) s.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, '').upcase.gsub(/\s+/, ' ').strip end
def muns(s) s.to_s.split(/\s*[|,]\s*/).map(&:strip).reject(&:empty?) end
celdas = Hash.new { |h, k| h[k] = { 'aprob_n' => 0, 'aprob_valor' => 0.0, 'tram_n' => 0, 'tram_costo' => 0.0, 'tram_registrados' => 0, 'tram_costo_registrado' => 0.0, 'tram_devueltos' => 0, 'nombres' => Hash.new(0) } }
excl = { 'aprobados' => 0, 'tramite' => 0 }
apr.each do |p|
  if p['departamento'] == 'Varios departamentos' then excl['aprobados'] += 1; next end
  ms = muns(p['municipio']); ms = ['SIN MUNICIPIO'] if ms.empty?
  ms.each do |m|
    c = celdas[[norm(p['departamento']), norm(m)]]
    c['aprob_n'] += 1; c['aprob_valor'] += p['valor_cop'].to_f / ms.size
    c['nombres'][[p['departamento'], m]] += 1
  end
end
tra.each do |p|
  ms = muns(p['municipio']); ms = ['SIN MUNICIPIO'] if ms.empty?
  ms.each do |m|
    c = celdas[[norm(p['departamento']), norm(m)]]
    c['tram_n'] += 1; c['tram_costo'] += p['costo_cop'].to_f / ms.size
    if p['estado_orden'] == 4 then c['tram_registrados'] += 1; c['tram_costo_registrado'] += p['costo_cop'].to_f / ms.size end
    c['tram_devueltos'] += 1 if p['estado_orden'] == 1
    c['nombres'][[p['departamento'], m]] += 1
  end
end
filas = celdas.map do |(dk, mk), c|
  dep, mun = c['nombres'].max_by { |_, n| n }[0]
  cat = if c['aprob_n'] > 0 && c['tram_n'] > 0 then 'Con aprobados y en trámite'
        elsif c['aprob_n'] > 0 then 'Solo aprobados'
        else 'Nuevo: solo en trámite' end
  { 'id' => "#{dk}|#{mk}".downcase.gsub(/[^a-z0-9|]+/, '-'), 'departamento' => dep, 'municipio' => mun, 'categoria' => cat,
    'aprob_n' => c['aprob_n'], 'aprob_valor' => c['aprob_valor'].round,
    'tram_n' => c['tram_n'], 'tram_costo' => c['tram_costo'].round,
    'tram_registrados' => c['tram_registrados'], 'tram_costo_registrado' => c['tram_costo_registrado'].round,
    'tram_devueltos' => c['tram_devueltos'] }
end.sort_by { |f| [-f['aprob_valor'] - f['tram_costo']] }
ids = filas.map { |f| f['id'] }; raise 'ids repetidos' if ids.uniq.size != ids.size
File.write(ARGV[2], JSON.generate(filas))
cats = Hash.new(0); filas.each { |f| cats[f['categoria']] += 1 }
STDERR.puts "#{filas.size} municipios; #{cats}; excluidos #{excl}"
