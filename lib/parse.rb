require 'roo-xls'

movimenti = Roo::Spreadsheet.open('test-data/ListaMovimenti.xls')

(22..30).each do |i|
  p movimenti.sheet('Lista Movimenti').row(i)
end
