#!/usr/bin/ruby -w

directory = "/home/mwnock/tmp/uvm-1.1d/src"
macro_db  = Hash.new
buffer    = ""
debug_cnt = 0

####################################################
#  macro item
####################################################
class Macro

  def initialize
    @name     = ""
    @lines    = 0
    @args     = ""
    @contents = ""
    @filename = ""
    @fileline = 0
  end

  def get_macro(macro_db,name)
    if(macro_db.has_key?(name))then
      return macro_db[name].contents
    else
      return ""
    end
  end

  def chk_macro(line)
    if(/\`(\w+)/ =~ line)then
      return $1
    else
      return ""
    end
  end

  def check(macro_db,line)
    @check_result = get_macro(macro_db,chk_macro(line))
    if(@check_result.length==0)then
      return 0
    else
      return 1
    end
  end

  def disp(macro_db,extract)
    @contents_array = contents.split("\n")
    print "----- " + filename + ", line=" + fileline.to_s + "\n"
    if(extract==0)then
      print contents + "\n"
    else
      @contents_array.each do |line|
        puts line
        #@disp_temp = check(macro_db,line)
        #if(@disp_temp==0)then
        #  puts line
        #else
        #  puts @check_result
        #end
      end
    end
  end

  attr_accessor :name, :lines, :args, :contents, :filename, :fileline

end

Dir::chdir(directory)
Dir::glob("**/*.sv*"){ |file|
  if(File::ftype(file)=="directory")then
    puts "dir: " + file
  else
    #puts "open " + file
    #macro = Hash.new
    sw    = false

    item  = Macro.new
    open(file) do |f|
      f.each_line do |line|
        # puts "----- " + file
        # puts line
        line.chomp

        begin
          next if(/^\s*\/\/.*/ =~ line)	# skip verilog comment
        rescue
          puts "*E Error detected while comment check. So skip this line. File=" + \
               directory + "/" + file + ", skip line is " + f.lineno.to_s
          next
        end

        # macro = Macro.new if(/^\s*\`define/ =~ line)

        if(/^\s*\`define\s+(\w+)\s*\\/ =~ line)then  # detect define macro (no arg)
          item.name  = $1
          item.lines = 1
          item.args  = ""
          item.filename = directory + "/" + file
          item.fileline = f.lineno
          sw          = true
          buffer      = ""
          #print "1 sw is " + sw.to_s + ", item is "
          #p item
        elsif(/^\s*\`define\s+(\w+)\s*\((.*)\)\s*\\/ =~ line)then  # detect define macro (arg)
          item.name  = $1
          item.lines = 1
          item.args  = $2
          item.filename = directory + "/" + file
          item.fileline = f.lineno
          sw          = true
          buffer      = ""
          #puts "2 sw is " + sw.to_s + ", item is "
          #p item
        elsif(/^\s*\`define\s+(\w+)\s*\((.*)\)\s*$/ =~ line)then  # detect define macro (no return)
          item.name     = $1
          item.lines    = 0
          item.args     = ""
          item.contents = line
          item.filename = directory + "/" + file
          item.fileline = f.lineno
          sw             = false
          macro_db[$1]   = item.clone
          #puts "3 sw is " + sw.to_s
        elsif(/^\s*\`define\s+(\w+)\s*$/ =~ line)then  # detect define macro (no arg)
          item.name     = $1
          item.lines    = 0
          item.args     = ""
          # puts "----- " + file
          # puts line
          item.contents = line
          item.filename = directory + "/" + file
          item.fileline = f.lineno
          sw             = false
          macro_db[$1]   = item.clone
          #puts "4 sw is " + sw.to_s
        else
          #print "5 sw is " + sw.to_s + ", item is "
          #p item
        end
  
        if(sw==true)then
          debug_cnt += 1
          #puts line
          #p line.class.to_s
          if(line!=nil && buffer!=nil)then
            # buffer += line + "\n"
            buffer += line
            if(/.*\\.*/ !~ line)then  # final line
              item.contents = buffer
                #print "buffer.kind_of? "
                #p buffer.kind_of?(String)
                #print "macro.instance_of? "
                ## p macro.contents.kind_of?(String)
                #p macro
                #puts "debug_cnt = " + debug_cnt.to_s
                #puts "DBG : " + file + ", " + f.lineno.to_s
              sw = false
              macro_db[item.name] = item.clone
              # puts "DBG " + line
            else
            end
          end
        end

      end
    end
  end
}

key = ""
while( !(key[0]=="q" || key[0]=="Q") )do
  print "uvm analyzer (q/Q exit) > "
  key = gets.chomp.split(/\s+/)

  if(key[0] == "list" && key.size==2)then
    # puts "list desu"
    macro_list = macro_db.keys
    macro_list.each do |list|
      # puts list
      begin
        if(/#{key[1]}/ =~ list)then
          puts list
        end
      rescue
        puts "*E Regexp Error"
        break
      end
    end
  elsif(macro_db.has_key?(key[0]))then
    macro_db[key[0]].disp(macro_db,0)
  else
    puts "No macro detected..."
  end
end
