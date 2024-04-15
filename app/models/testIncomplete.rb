require_relative 'IncompleteDate.rb'

d1 = IncompleteDate.new(str:'2023')
d2 = IncompleteDate.new(str:'????-12-??')
d3 = IncompleteDate.new(str:'2023-05')
d4 = IncompleteDate.new(str:'????-??-05')
d5 = IncompleteDate.new(str:'2023-??-29')
d6 = IncompleteDate.new(str:'????-12-24')
d7 = IncompleteDate.new(str:'2022-12-24')


puts IncompleteDate.new(str:'2022-12-24') - IncompleteDate.new(str:'2022-12-20')    # 4
puts IncompleteDate.new(str:'2022-12-24') - IncompleteDate.new(str:'2022-12-24')    # 0
puts IncompleteDate.new(str:'2022-12-24') - IncompleteDate.new(str:'2022-12-30')    # -6
puts IncompleteDate.new(str:'2022-12') - IncompleteDate.new(str:'2022-10')
puts IncompleteDate.new(str:'2022') - IncompleteDate.new(str:'2010')

puts IncompleteDate.new(str:'2010-10-05').to(IncompleteDate.new(str:'2023-05-29'))
puts IncompleteDate.new(str:'2010-10-05').to(IncompleteDate.new(str:'2023-10-05'))
puts IncompleteDate.new(str:'1970-04-16').to      # 0012-07-24
puts IncompleteDate.new(str:'1970-06-13').to
puts IncompleteDate.new(str:'1937').to
puts IncompleteDate.new(str:'1919').to(IncompleteDate.new(str:'1949'))
puts IncompleteDate.new(str:'????-05-29').to
puts IncompleteDate.new(str:'????-05-28').to
puts IncompleteDate.new(str:'1970-05').to
puts IncompleteDate.new(str:'2023-04').to
puts IncompleteDate.new(str:'2023-05-30').to
puts IncompleteDate.new(str:'1937-10-01').to(IncompleteDate.new(str:'1937-10-10'))
puts IncompleteDate.new(str:'1937-10-01').to(IncompleteDate.new(str:'1937-10-02'))
puts IncompleteDate.new(str:'1970-04-16').to(IncompleteDate.new(str:'1970-05-22'))
puts IncompleteDate.new(str:'1970-04-16').to(IncompleteDate.new(str:'1970-04-16'))
puts IncompleteDate.new(str:'2023-05-31').to
puts IncompleteDate.new(str:'2010-12').to(IncompleteDate.new(str:'2010-12-06'))
puts IncompleteDate.new(str:'1975').to(IncompleteDate.new(str:'1975-04-29'))
puts IncompleteDate.new(str:'1911-7-15').to(IncompleteDate.new(str:'1944-12'))
puts IncompleteDate.new(str:'2023-04').to(IncompleteDate.new(str:'2023-12'))
puts IncompleteDate.new(str:'2023-04').to(IncompleteDate.new(str:'2023-03'))

puts 10
