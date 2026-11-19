# encoding: utf-8
# Une proyectos aprobados (ART) con su ficha de MapaInversiones (DNP) y clasifica su ejecución.
# Uso: ruby armar_ejecucion.rb proyectos.json mapainversiones_fichas.json ejecucion.json
require 'json'
apr = JSON.parse(File.read(ARGV[0], encoding: 'UTF-8'))
fic = JSON.parse(File.read(ARGV[1], encoding: 'UTF-8'))
ANIO_ACTUAL = 2026
filas = apr.map do |p|
  x = fic[p['bpin']]
  fis = x ? x['AvanceFisico'].to_f : 0.0
  fin_h = x ? x['HorizonteProyecto'].to_s[-4..-1].to_i : nil
  est = x ? x['EstadoProyecto'].to_s : ''
  sit, orden = if x.nil? || est == 'Formulación' then ['Sin ficha o en formulación', 5]
               elsif fis >= 99 then ['Terminada (avance físico ≥ 99 %)', 1]
               elsif fis > 0 then ['En obra con avance reportado', 2]
               elsif est == 'En Ejecución' then ['En ejecución sin avance reportado', 3]
               else ['Viable, sin seguimiento de obra', 4] end
  pago = x ? x['ValorPagoProyecto'].to_f : 0.0
  coherente = pago > 0 && pago <= p['valor_cop'] * 1.05
  {
    'id' => p['id'], 'bpin' => p['bpin'], 'anio' => p['anio'], 'nombre' => p['nombre'], 'ministerio' => p['ministerio'],
    'departamento' => p['departamento'], 'municipio' => p['municipio'], 'modalidad' => p['modalidad'], 'valor_cop' => p['valor_cop'],
    'situacion' => sit, 'situacion_orden' => orden,
    'avance_fisico' => fis.round(1), 'avance_financiero' => x ? x['AvanceFinanciero'].to_f.round(1) : 0,
    'pago_cop' => coherente ? pago.round : nil, 'pago_pct' => coherente ? (pago / p['valor_cop']).round(4) : nil,
    'pago_incoherente' => pago > p['valor_cop'] * 1.05,
    'estado_dnp' => x ? est : 'Sin ficha', 'subestado_dnp' => x ? x['SubEstadoProyecto'].to_s.gsub(/\s+/, ' ').strip : '',
    'horizonte' => x ? x['HorizonteProyecto'] : '', 'fin_horizonte' => fin_h,
    'vencido' => !!(x && est == 'En Ejecución' && fis < 99 && fin_h && fin_h < ANIO_ACTUAL),
  }
end
File.write(ARGV[2], JSON.generate(filas))
t = Hash.new(0); filas.each { |f| t[f['situacion']] += 1 }
STDERR.puts "#{filas.size} proyectos; #{t}; vencidos #{filas.count { |f| f['vencido'] }}; con pago coherente #{filas.count { |f| f['pago_pct'] }}"
