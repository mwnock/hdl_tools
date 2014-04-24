#!/usr/bin/ruby -w

tool_name = "uvm_code_helper > "

puts tool_name + "Please input UVM instance line(s), then 'e' + enter."
info = ""
info_array = []
while(!(info.chomp == "e"))do
  info = STDIN.gets
  info_array << info
end
info_array = info_array[0..info_array.size-2]

#puts "---"
#info_array.each do |line|
#  puts line
#end

quest = 0
while( !(quest>=1 && quest<=2) )do
  puts tool_name + "What kind of code do you want to generate ?"
  puts " 1. create instance"
  puts " 2. create sequence"
  print tool_name
  quest = STDIN.gets.chomp.to_i
end

info_array.each do |line|
  line = line.to_s # array to string for using gsub (String class method)
  line = line.gsub(/^\s*/, "")
  line = line.gsub(/\s*;/, "")

  mode = 0
  ### 構文解析
  if(/^\s*(\w+)\s+(\w+)/ =~ line)then	# not parameterized class
    items = line.split(/\s+/)
    comp = items[0]
    inst = items[1]
    #puts "mode1 comp=#{comp}, inst=#{inst}"
    mode = 1
  # elsif(/^\s*(\w+)\s*\#\(\s*(\w+)\s*\)\s+(\w+)/ =~ line)then	# parameterized class (hoge)
  elsif(/\#/ =~ line)then
    line  = line.gsub(/#/," ")
    line  = line.gsub(/\(/,"")
    line  = line.gsub(/\)/,"")
    items = line.split(/\s+/)
    comp  = items[0]
    param = items[1]
    inst  = items[2]
    #puts "mode2 comp=#{comp}, param=#{param}, inst=#{inst}"
    mode  = 2
  else
    puts tool_name + "Failed to analyze code... -> #{line}"
    next
  end

  if quest==1 then      # not parameterized class
    if mode==1 then
      puts "#{inst} = #{comp}::type_id::create(\"#{inst}\", this);"
    elsif mode==2 then  # parameterized class
      puts "#{inst} = #{comp}\#(#{param})::type_id::create(\"#{inst}\", this);"
    else
      puts tool_name "E001 Program BUG!!!"
      next
    end

  elsif quest==2 then
  else
    puts tool_name "E002 Program BUG!!!"
    next
  end
end
