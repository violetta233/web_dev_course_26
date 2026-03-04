require 'date' #встроенный модуль Ruby для работы с датами

# проверяем аргументы в командной строке
if ARGV.size != 4
  puts "Пример: ruby build_calendar.rb teams.txt 01.08.2026 01.07.2028 calendar.txt"
  exit 1
end

teams_file, start_str, end_str, output_file = ARGV

# проверяем существует ли файл с командами
unless File.exist?(teams_file)
  puts "Файл #{teams_file} не найден"
  exit 1
end

# парсинг даты
begin
  start_date = Date.strptime(start_str, '%d.%m.%Y')
  end_date   = Date.strptime(end_str, '%d.%m.%Y')
rescue ArgumentError
  puts "Неправильно написана дата, нужно: ДД.ММ.ГГГГ"
  exit 1
end

# проверка даты
exit 1 if start_date >= end_date

# читаем команды из файла
teams = []
File.readlines(teams_file, encoding: 'UTF-8').each do |line|
  line = line.strip #Удаляет лишние пробелы
  next if line.empty?
  if line.include?(' — ')
    name, city = line.split(' — ', 2).map(&:strip)
    teams << {name: name, city: city}
  end
end

# без команд смысла нет
if teams.size < 2
  puts "Надо минимум 2 команды"
  exit 1
end


puts "Команд: #{teams.size}"

# создаем все возможные пары
matches = teams.combination(2).map do |t1, t2|
  {t1: t1[:name], t2: t2[:name], c1: t1[:city], c2: t2[:city]}
end
matches.shuffle!
puts "Матчей: #{matches.size}"

# собираем все пятницы, субботы и воскресенья в нашем диапазоне
play_days = (start_date..end_date).select { |d| [0, 5, 6].include?(d.wday) }

# времена матчей
times = ['12:00', '15:00', '18:00']

# составляем расписание
schedule = []

matches_cop = matches.dup # копируем

max_games = 2
play_days.each do |date|
  games_today = []

times.each do |time|
  max_games.times do
    break if matches_cop.empty?
      
    games_today << { time: time, **matches_cop.shift }
  end
  break if matches_cop.empty?
end
schedule << { date: date, games: games_today} unless games_today.empty?
end

# проверяем оставшиеся матчи
if matches_cop.any?
  puts "Не успели сыграть #{matches_cop.size} матчей. Нужно добавить дней"
else
  puts "Все прошло. Турнирных дней: #{schedule.size}"
end

# сохраняем в файл
WEEKDAYS = %w[Вс Пн Вт Ср Чт Пт Сб] #строки без кавычек

File.open(output_file, 'w:UTF-8') do |f|
   f.puts "Календарь турниров",
         "#{start_date.strftime('%d.%m.%Y')} - #{end_date.strftime('%d.%m.%Y')}",
         "Команды: #{teams.size}, Матчи: #{matches.size}",
         "-" * 50
  
  schedule.each do |day|
    date_str = day[:date].strftime('%d.%m.%Y')
    f.puts "\n#{WEEKDAYS[day[:date].wday]}, #{date_str}:"
    
      # массив игр для текущего дня
      day[:games].each do |g|
      f.puts "  #{g[:time]}  #{g[:t1]} (#{g[:c1]}) - #{g[:t2]} (#{g[:c2]})"
    end
  end
end

puts "Готов файл #{output_file}"