# encoding: utf-8
# Limpia la base de resultados OxI de la ART (2018-2025) y la deja como filas JSON.
require 'json'
crudo = JSON.parse(File.read(ARGV[0], encoding: 'UTF-8'))
SECTOR = {
  'EDUCACIÓN' => ['Educación', 'mineducacion'],
  'INFRAESTRUCTURA VIAL' => ['Infraestructura vial', 'mintransporte'],
  'ENERGÍA' => ['Energía', 'minenergia'],
  'MINAS Y ENERGÍA' => ['Energía', 'minenergia'],
  'AGUA POTABLE Y SANEAMIENTO BÁSICO' => ['Agua potable y saneamiento', 'minvivienda'],
  'EDUCACIÓN - ICBF' => ['Primera infancia (ICBF)', 'icbf'],
  'GESTIÓN DEL RIESGO' => ['Gestión del riesgo', 'ungrd'],
  'PAGOS POR SERVICIOS AMBIENTALES - PSA' => ['Pagos por servicios ambientales', 'minambiente'],
  'SALUD' => ['Salud', 'minsalud'],
  'EDUCACIÓN - TRABAJO' => ['Formación para el trabajo', 'mintrabajo'],
  'TECNOLOGÍA DE LA INFORMACIÓN Y LAS COMUNICACIONES' => ['TIC', 'mintic'],
  'DEPORTE' => ['Deporte', 'mindeporte'],
}
MIN = {
  'mineducacion' => 'MinEducación', 'mintransporte' => 'MinTransporte', 'minenergia' => 'MinEnergía',
  'minvivienda' => 'MinVivienda', 'icbf' => 'ICBF', 'ungrd' => 'UNGRD', 'minambiente' => 'MinAmbiente',
  'minsalud' => 'MinSalud', 'mintrabajo' => 'MinTrabajo', 'mintic' => 'MinTIC', 'mindeporte' => 'MinDeporte',
}
def limpio(s) s.to_s.gsub(/\s+/, ' ').strip end
def multi(s) limpio(s.to_s.gsub(/\s*\n\s*/, '|')).split(/\s*\|\s*/).reject(&:empty?) end
filas = crudo[2..-1].select { |x| x && x[2].to_s =~ /^\d{4}$/ }.map do |x|
  sec, mid = SECTOR.fetch(limpio(x[6]).upcase) { raise "Sector sin mapear: #{x[6]}" }
  deptos = multi(x[7].to_s.gsub(/ Y |, /, '|'))
  {
    'id' => "p#{limpio(x[0])}",
    'bpin' => limpio(x[1]),
    'anio' => x[2].to_i,
    'modalidad' => limpio(x[3]).capitalize,
    'nombre' => limpio(x[4]),
    'valor_cop' => x[5].to_f.round,
    'sector' => sec,
    'ministerio_id' => mid,
    'ministerio' => MIN[mid],
    'departamento' => deptos.size > 1 ? 'Varios departamentos' : deptos.first.to_s.sub('QUINDIO', 'QUINDÍO'),
    'departamentos' => deptos.join(', '),
    'municipio' => multi(x[8]).join(', '),
    'subregion_pdet' => multi(x[9]).join(', '),
    'contribuyente' => multi(x[10]).join('; '),
  }
end
ids = filas.map { |f| f['id'] }
raise 'ids repetidos' if ids.uniq.size != ids.size
File.write(ARGV[1], JSON.generate(filas))
STDERR.puts "#{filas.size} proyectos, total #{filas.sum { |f| f['valor_cop'] }}"
