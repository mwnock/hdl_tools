#!/usr/bin/ruby -w

tool_name  = "uvm_code_helper > "
idt        = "    "
idt_sw     = true
item_array = []

class Item
  def initialize(m,a,b,c=nil)
    @mode  = m
    @comp  = a
    @inst  = b
    @param = c
  end
  def get_comp_info
    return [@inst,@comp,@param]
  end
  def get_mode
    @mode
  end
  def get_len
    @inst.length
  end
end

mode_kind = 0
while( !(mode_kind>=1 && mode_kind<=2) )do
  puts tool_name + "Please select mode"
  puts " 1. phasing template"
  puts " 2. create instance/sequence"
  print tool_name
  mode_kind = STDIN.gets.chomp.to_i
end

### phasing template
##############################
if mode_kind==1 then
  phase = "new"
  puts <<"HERE"
=== #{phase} =======================================
----- for uvm_component base class (uvm_env, uvm_driver, etc...)
#{idt}function #{phase}(string name, uvm_component parent);
#{idt}#{idt}super.new(name,parent);
#{idt}endfunction : #{phase}
----- for uvm_test base class
#{idt}function new(string name="modify_this", uvm_component parent=null);
#{idt}#{idt}super.new(name,parent);
#{idt}endfunction : new
----- for uvm_object base class (uvm_sequence, etc...)
#{idt}function new(string name="modify_this");
#{idt}#{idt}super.new(name);
#{idt}endfunction : new

HERE

  phase = "build_phase"
  puts <<"HERE"
=== #{phase} =======================================
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}super.build_phase(phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

  phase = "connect_phase"
  puts <<"HERE"
=== #{phase} =======================================
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

  phase = "end_of_elaboration_phase"
  puts <<"HERE"
=== #{phase} ============================
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

  phase = "start_of_simulation_phase"
  puts <<"HERE"
=== #{phase} ===========
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

  phase = "run_phase"
  puts <<"HERE"
=== #{phase} ===========
#{idt}task #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endtask : #{phase}

HERE

  phase = "extract_phase"
  puts <<"HERE"
=== #{phase} ===========
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

  phase = "check_phase"
  puts <<"HERE"
=== #{phase} ===========
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

  phase = "report_phase"
  puts <<"HERE"
=== #{phase} ===========
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

  phase = "final_phase"
  puts <<"HERE"
=== #{phase} ===========
#{idt}function void #{phase}(uvm_phase phase);
#{idt}#{idt}// insert your codes
#{idt}endfunction : #{phase}

HERE

### create instance/sequence
##############################
elsif mode_kind==2 then
  puts tool_name + "Please input UVM instance line(s), then 'e' + enter."
  info = ""
  info_array = []
  while(!(info.chomp == "e"))do
    info = STDIN.gets
    info_array << info
  end
  info_array = info_array[0..info_array.size-2]
  
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
      item_array.push Item.new(1,$1,$2)
    elsif(/^\s*(\w+)\s*#\(\s*(\w+)\s*\)\s+(\w+)/=~ line)then	# parameterized class
      item_array.push Item.new(2,$1,$3,$2)
    else
      puts tool_name + "Failed to analyze code... -> #{line}"
      next
    end
  end
end

### check length
len = 0
item_array.each do |item|
  len = item.get_len if(len < item.get_len)
end

### extract
item_array.each do |item|
  ta = item.get_comp_info	# tmp_array
  ti = 1                        # tmp_indent
  ti = 1+len-item.get_len if(idt_sw)
  ### create component
  if quest==1 then
    if item.get_mode==1 then      # not parameterized class
      puts "#{ta[0]}" + " "*ti + "= #{ta[1]}::type_id::create(\"#{ta[0]}\", this);"
    elsif item.get_mode==2 then  # parameterized class
      puts "#{ta[0]}" + " "*ti + "= #{ta[1]}\#(#{ta[2]})::type_id::create(\"#{ta[0]}\", this);"
    else
      puts tool_name + "E001 Program BUG!!!"
      next
    end

  ### create sequence
  elsif quest==2 then
    if item.get_mode==1 then
      puts "--- case1 ---"
      puts "#{ta[0]}" + " "*ti + "= #{ta[1]}::type_id::create(\"#{ta[0]}\");"
      puts "--- case2 ---"
      puts "#{ta[0]}" + " "*ti + "= #{ta[1]}::type_id::create(\"#{ta[0]}\",,get_full_name());"
    else
      puts tool_name + "Failed to analyze sequence instance code..."
    end
  else
    puts tool_name "E002 Program BUG!!!"
    next
  end
end
