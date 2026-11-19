# encoding: utf-8
# Descarga la ficha general (FichasProyectosDG) de MapaInversiones (DNP) para cada BPIN de proyectos.json.
# Uso: ruby descargar_mapainversiones.rb proyectos.json salida.json
require 'json'; require 'net/http'; require 'uri'
bpins = JSON.parse(File.read(ARGV[0], encoding: 'UTF-8')).map { |p| p['bpin'] }.uniq
CAMPOS = %w[Bpin EstadoProyecto SubEstadoProyecto AvanceFisico AvanceFinanciero ValorTotalProyecto ValorSolicitadoProyecto
            ValorVigenteProyecto ValorPagoProyecto ValorObligacionProyecto HorizonteProyecto IdFechaPeriodo TipoProyecto
            EntidadEjecutora SectorProyecto FechaCorte]
out = {}
http = Net::HTTP.new('mapainversiones.dnp.gov.co', 443); http.use_ssl = true; http.read_timeout = 30
http.start do |h|
  bpins.each_with_index do |b, i|
    2.times do
      begin
        res = h.get("/ApiProxy/Get?FichasProyectosDG?bpin=#{b}", 'User-Agent' => 'Mozilla/5.0 (investigacion OxI)')
        body = res.body.to_s.force_encoding('UTF-8')
        j = body.strip.empty? || body.strip == 'null' ? nil : JSON.parse(body)
        out[b] = j ? j.slice(*CAMPOS) : nil
        break
      rescue => e
        out[b] = { 'error' => e.message[0, 80] }; sleep 1
      end
    end
    sleep 0.2
    STDERR.print "#{i + 1}/#{bpins.size}\r" if (i % 50).zero?
  end
end
File.write(ARGV[1], JSON.pretty_generate(out))
STDERR.puts "\n#{out.size} fichas; sin ficha: #{out.count { |_, v| v.nil? }}; errores: #{out.count { |_, v| v.is_a?(Hash) && v['error'] }}"
