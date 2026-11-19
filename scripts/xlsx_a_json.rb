# encoding: utf-8
# Convierte la primera hoja de un xlsx descomprimido (carpeta) a JSON de filas crudas.
require 'rexml/document'; require 'json'
dir = ARGV[0]
ss = []
sst = File.join(dir, 'xl/sharedStrings.xml')
if File.exist?(sst)
  REXML::Document.new(File.read(sst, encoding: 'UTF-8')).elements.each('sst/si') { |si| ss << si.get_elements('.//t').map(&:text).join }
end
doc = REXML::Document.new(File.read(File.join(dir, 'xl/worksheets/sheet1.xml'), encoding: 'UTF-8'))
col = ->(ref) { ref[/[A-Z]+/].chars.inject(0) { |a, c| a * 26 + (c.ord - 64) } - 1 }
rows = []
doc.elements.each('worksheet/sheetData/row') do |r|
  row = []
  r.elements.each('c') do |c|
    v = c.elements['v']&.text
    v = c.get_elements('.//t').map(&:text).join if c.attributes['t'] == 'inlineStr'
    v = ss[v.to_i] if c.attributes['t'] == 's' && v
    row[col.(c.attributes['r'])] = v
  end
  rows << row
end
puts JSON.generate(rows)
