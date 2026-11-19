# encoding: utf-8
# Para los proyectos con plazo vencido: descarga sus productos en MapaInversiones (meta, ejecutado, avance)
# y los clasifica por nivel de alerta.
# Uso: ruby revisar_vencidos.rb ejecucion.json productos_vencidos_raw.json vencidos.json
require 'json'; require 'net/http'
eje = JSON.parse(File.read(ARGV[0], encoding: 'UTF-8'))
venc = eje.select { |p| p['vencido'] }
raw = File.exist?(ARGV[1]) ? JSON.parse(File.read(ARGV[1])) : {}
http = Net::HTTP.new('mapainversiones.dnp.gov.co', 443); http.use_ssl = true; http.read_timeout = 30
http.start do |h|
  venc.each do |p|
    next if raw.key?(p['bpin'])
    begin
      res = h.get("/ApiProxy/Get?FichasProyectosProductos?bpin=#{p['bpin']}", 'User-Agent' => 'Mozilla/5.0 (investigacion OxI)')
      b = res.body.to_s.force_encoding('UTF-8').strip
      raw[p['bpin']] = (b.empty? || b == 'null') ? [] : JSON.parse(b)
    rescue => e
      raw[p['bpin']] = { 'error' => e.message[0, 80] }
    end
    sleep 0.2
  end
end
File.write(ARGV[1], JSON.pretty_generate(raw))
num = ->(s) { s.to_s.gsub('.', '').tr(',', '.').to_f }  # "1.234,56" -> 1234.56
CORTE = 2026 + 10 / 12.0  # 1 nov 2026, en años
filas = venc.map do |p|
  prods = raw[p['bpin']].is_a?(Array) ? raw[p['bpin']] : []
  costo = prods.sum { |x| num.(x['Costo']) }
  # avance de productos ponderado por costo (AvanceMeta viene en %)
  av_prod = costo > 0 ? prods.sum { |x| num.(x['AvanceMeta']) * num.(x['Costo']) } / costo : (prods.empty? ? 0 : prods.sum { |x| num.(x['AvanceMeta']) } / prods.size)
  av_prod = [[av_prod, 0].max, 100].min
  senal = [p['avance_fisico'].to_f, av_prod].max
  meses = ((CORTE - (p['fin_horizonte'].to_i + 1)) * 12).round
  # Pagada en 50 % o más sin avance reportado: probable ejecución sin reporte, se separa de las alertas.
  pagado_sin = !!(p['pago_pct'] && p['pago_pct'] >= 0.5 && senal == 0)
  nivel, orden = if pagado_sin then ['Pagada, sin avance reportado', 3]
                 elsif senal == 0 && p['fin_horizonte'].to_i <= 2024 then ['Crítica', 1]
                 elsif senal < 50 then ['Alta', 2]
                 else ['Media', 4] end
  {
    'id' => p['id'], 'bpin' => p['bpin'], 'anio' => p['anio'], 'nombre' => p['nombre'], 'ministerio' => p['ministerio'],
    'departamento' => p['departamento'], 'municipio' => p['municipio'], 'modalidad' => p['modalidad'], 'valor_cop' => p['valor_cop'],
    'horizonte' => p['horizonte'], 'fin_horizonte' => p['fin_horizonte'], 'meses_vencido' => meses,
    'avance_fisico' => p['avance_fisico'], 'avance_productos' => av_prod.round(1), 'senal_avance' => senal.round(1),
    'pago_pct' => p['pago_pct'], 'pagado_sin_avance' => !!(p['pago_pct'] && p['pago_pct'] >= 0.5 && senal == 0),
    'productos' => prods.map { |x| x['Producto'].to_s.sub(/\(Producto principal del proyecto\)/i, '').gsub(/\s+/, ' ').strip }.uniq.join('; '),
    'nivel' => nivel, 'nivel_orden' => orden, 'subestado_dnp' => p['subestado_dnp'],
  }
end
File.write(ARGV[2], JSON.generate(filas))
t = Hash.new(0); filas.each { |f| t[f['nivel']] += 1 }
STDERR.puts "#{filas.size} vencidos; #{t}; con avance de productos > 0: #{filas.count { |f| f['avance_productos'] > 0 }}; pagado sin avance: #{filas.count { |f| f['pagado_sin_avance'] }}"
