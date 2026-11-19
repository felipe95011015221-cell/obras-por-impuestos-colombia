# encoding: utf-8
# Limpia el listado ART de proyectos en prefactibilidad/factibilidad en trámite y lo deja como filas JSON.
require 'json'
crudo = JSON.parse(File.read(ARGV[0], encoding: 'UTF-8'))
LINEA = {
  'INFRAESTRUCTURA VIAL' => ['Infraestructura vial', 'mintransporte'],
  'EDUCACIÓN PÚBLICA' => ['Educación', 'mineducacion'],
  'EDUCACIÓN PÚBLICA - TRABAJO' => ['Formación para el trabajo', 'mintrabajo'],
  'EDUCACIÓN - ICBF' => ['Primera infancia (ICBF)', 'icbf'],
  'SALUD' => ['Salud', 'minsalud'],
  'TECNOLOGÍAS DE LA INFORMACIÓN Y LAS COMUNICACIONES' => ['TIC', 'mintic'],
  'PAGO POR SERVICIOS AMBIENTALES' => ['Pagos por servicios ambientales', 'minambiente'],
  'ADAPTACIÓN AL CAMBIO CLIMÁTICO' => ['Adaptación al cambio climático', 'minambiente'],
  'GESTIÓN DEL RIESGO' => ['Gestión del riesgo', 'ungrd'],
  'INFRAESTRUCTURA CULTURAL' => ['Infraestructura cultural', 'mincultura'],
  'INFRAESTRUCTURA DEPORTIVA' => ['Infraestructura deportiva', 'mindeporte'],
  'ENERGÍA' => ['Energía', 'minenergia'],
  'ENERGÍA - GAS' => ['Energía (gas)', 'minenergia'],
  'AGUA POTABLE Y SANEAMIENTO BÁSICO' => ['Agua potable y saneamiento', 'minvivienda'],
  'INFRAESTRUCTURA PRODUCTIVA' => ['Infraestructura productiva', 'por_definir'],
}
MIN = {
  'mineducacion' => 'MinEducación', 'mintransporte' => 'MinTransporte', 'minenergia' => 'MinEnergía',
  'minvivienda' => 'MinVivienda', 'icbf' => 'ICBF', 'ungrd' => 'UNGRD', 'minambiente' => 'MinAmbiente',
  'minsalud' => 'MinSalud', 'mintrabajo' => 'MinTrabajo', 'mintic' => 'MinTIC', 'mindeporte' => 'MinDeporte',
  'mincultura' => 'MinCulturas', 'por_definir' => 'Por definir',
}
# Estados SUIFP en el orden del trámite (1 = más avanzado)
ESTADO = {
  'devolver a mga web' => ['Devuelto con observaciones', 1],
  'cabeza de sector jefe de planeación' => ['En revisión del ministerio', 2],
  'control posterior de viabilidad' => ['Control posterior DNP', 3],
  'registrado actualizado' => ['Registrado: financiable', 4],
}
def limpio(s) s.to_s.gsub(/\s+/, ' ').strip end
hi = crudo.index { |x| x && x[1].to_s.strip == 'ID MGA' }
corte = crudo.flatten.compact.find { |c| c.to_s =~ /^Corte:/ }
filas = crudo[(hi + 1)..-1].select { |x| x && x[0].to_s =~ /^\d+$/ }.map do |x|
  linea, mid = LINEA.fetch(limpio(x[10]).upcase) { raise "Línea sin mapear: #{x[10]}" }
  est, orden = ESTADO.fetch(limpio(x[13]).downcase) { raise "Estado sin mapear: #{x[13]}" }
  {
    'id' => "t#{limpio(x[1])}",
    'bpin' => limpio(x[2]),
    'fase' => limpio(x[3]).capitalize,
    'proponente' => limpio(x[4]),
    'tipo_proponente' => limpio(x[5]).capitalize.sub(' - ese', ' - ESE'),
    'departamento' => limpio(x[6]),
    'municipio' => limpio(x[7]),
    'codigo_dane' => limpio(x[8]),
    'subregion_pdet' => limpio(x[9]),
    'linea' => linea,
    'ministerio_id' => mid,
    'ministerio' => MIN[mid],
    'nombre' => limpio(x[11]),
    'costo_cop' => x[12].to_f.round,
    'estado' => est,
    'estado_orden' => orden,
  }
end
ids = filas.map { |f| f['id'] }
raise 'ids repetidos' if ids.uniq.size != ids.size
File.write(ARGV[1], JSON.generate(filas))
STDERR.puts "#{filas.size} proyectos en trámite (#{corte}), costo total #{filas.sum { |f| f['costo_cop'] }}"
