#!/usr/bin/ruby -w
# vi: set fileencoding=utf-8

#--------------------------------------------------------------------
#-- class Uvm_agent
#--   - driver, sequencer and monitor's name are created by agent name
#--------------------------------------------------------------------
class Uvm_model
  def initialize(model_name, agent_name, agent_inst_name, multi, vif_name)
    @indent = "  "
    @head   = "_"
    @model_name = model_name
    @agent_name = agent_name
    if agent_inst_name == "" then
      @agent_inst_name  = agent_name
    else
      @agent_inst_name  = agent_inst_name
    end
    @multi = multi
    @vif_name = vif_name
  end

  def indent
    @indent
  end

  def model
    @model_name
  end

  def model_name
    @model_name
  end

  def agent(sel)
    case sel
      when "class"
        "#{@model_name}_#{@agent_name}_agent"
      when "agent"
        @agent_name
      when "inst"
        #"#{@agent_name}"
        @agent_inst_name
      when "multi"
        @multi
      else
        "unknown"
    end
  end

  def set_agent_inst(name)
    @inst_name = name
  end

  def driver(sel)
    case sel
      when "class"
        "#{@model_name}_#{@agent_name}_driver"
      when "inst"
        "driver"
      when "connect"
        "driver.seq_item_port.connect(sequencer.seq_item_export)"
      else
        "unknown_driver"
    end
  end

  def monitor(sel)
    case sel
      when "class"
        "#{@model_name}_#{@agent_name}_monitor"
      when "inst"
        "monitor"
      else
        "unknown_monitor"
    end
  end

  def sequencer(sel)
    case sel
      when "class"
        "#{@model_name}_#{@agent_name}_sequencer"
      when "inst"
        "sequencer"
      else
        "unknown_sequencer"
    end
  end

  def vif_name
    @vif_name
  end

  def seq_item
    "#{@model_name}_#{@agent_name}_seq_item"
  end

  def vif_code
    str = <<"HERE"
#{@indent*2}begin
#{@indent*3}bit status;
#{@indent*3}status = uvm_config_db#(virtual #{@vif_name})::get(this, "", "vif", vif);
#{@indent*3}if(status==1'b0)
#{@indent*4}uvm_report_fatal("NOVIF", {"virtual interface must be set for: ",get_full_name(),".vif"});
#{@indent*2}end
HERE
    str
  end

  def seq_lib
    "#{@model_name}_#{@agent_name}_seq_lib"
  end

end

#--------------------------------------------------------------------
#-- Local variable, method...
#--------------------------------------------------------------------
prompt = "uvm_code_gen >"

def new_begin(type, name=nil)
  case type
    when "uvm_test"
      "function new (string name=\"#{name}\", uvm_component parent=null);"
    when "uvm_component"
      "function new (string name, uvm_component parent);"
    when "uvm_object"
      "function new (string name=\"#{name}\");"
    else
      nil
  end
end

new_end             = "endfunction : new"
build_phase_begin   = "function void build_phase(uvm_phase phase);"
build_super         = "super.build_phase(phase);"
build_phase_end     = "endfunction : build_phase"
connect_phase_begin = "function void connect_phase(uvm_phase phase);"
connect_phase_end   = "endfunction : connect_phase"
run_phase_begin     = "virtual task run_phase(uvm_phase phase);"
run_phase_end       = "endtask : run_phase"
extract_phase_begin = "virtual function void extract_phase(uvm_phase phase);"
extract_phase_end   = "endfunction : extract_phase"
report_phase_begin  = "virtual function void report_phase(uvm_phase phase);"
report_phase_end    = "endfunction : report_phase"

#--------------------------------------------------------------------
#-- Question
#--------------------------------------------------------------------
printf("%s Please input model name : ", prompt)
model_name = STDIN.gets.chomp

printf("%s How many agent-kind do you need ? (1-9) : ", prompt)
agent_kind_num = STDIN.gets.chomp.to_i
uvm_model_array = Array.new(agent_kind_num)

0.upto(agent_kind_num-1) do |num|
  printf("%s Number %d agent name ? : ", prompt, num+1)
  agent_name = STDIN.gets.chomp

  printf("%s Number %d agent has multi ? (y/n) : ", prompt, num+1)
  multi = STDIN.gets.chomp

  agent_inst_name = ""
  if multi=="y" then
    agent_inst_name = "#{agent_name}s"
  end

  printf("%s Number %d agent's using interface name : ", prompt, num+1)
  vif_name = STDIN.gets.chomp

  #m_uvm_model = Uvm_model.new(model_name, agent_name, multi, vif_name)
  m_uvm_model = Uvm_model.new(model_name, agent_name, agent_inst_name, multi, vif_name)
  uvm_model_array[num] = m_uvm_model.clone
end

#--------------------------------------------------------------------
#-- mkdir
#--------------------------------------------------------------------
dir_model_body = "#{model_name}_model/body"
dir_model_tb   = "#{model_name}_model/tb"
dir_model_seq  = "#{model_name}_model/seq"
Dir::mkdir("./#{model_name}_model")
Dir::mkdir(dir_model_body)
Dir::mkdir(dir_model_tb)
Dir::mkdir(dir_model_seq)

#--------------------------------------------------------------------
#-- create model body
#--------------------------------------------------------------------
# create uvm_env
class_name = model_name + "_env"
open("#{dir_model_body}/#{class_name}.sv", "w") {|file|
  indent = uvm_model_array[0].indent()
  ### class header
  file.puts "`ifndef #{class_name.upcase}"
  file.puts "`define #{class_name.upcase}"
  file.puts "class #{class_name} extends uvm_env;"
  file.puts ""

  ### members (agent, etc...)
  uvm_model_array.each do |item|
    str = ""
    #str = "s[]" if(item.agent("multi")=="y")
    str = "[]" if(item.agent("multi")=="y")
    file.puts "#{item.indent}#{item.agent("class")} #{item.agent("inst")}#{str};"
  end

  ### members (other variables)
  utils_flag = 0
  uvm_model_array.each do |item|
    if(item.agent("multi")=="y")then
      #file.puts "#{item.indent}int num_#{item.agent("inst")}s;"
      file.puts "#{item.indent}int num_#{item.agent("inst")};"
      utils_flag = 1
    end
  end
  file.puts ""

  ### regitered UVM factory and UVM automation
  if(utils_flag==0)then
    file.puts "#{indent}`uvm_component_utils(#{class_name})"
  else
    file.puts "#{indent}`uvm_component_utils_begin(#{class_name})"
    uvm_model_array.each do |item|
      if(item.agent("multi")=="y")then
        #file.puts "#{indent*2}`uvm_field_int(num_#{item.agent("inst")}s, UVM_DEFAULT)"
        file.puts "#{indent*2}`uvm_field_int(num_#{item.agent("inst")}, UVM_DEFAULT)"
      end
    end
    file.puts "#{indent}`uvm_component_utils_end"
  end
  file.puts ""

  ### Constructor
  file.puts "#{indent}#{new_begin("uvm_component")}"
  file.puts "#{indent*2}super.new(name,parent);"
  file.puts "#{indent}#{new_end}"
  file.puts ""

  ### Build
  file.puts "#{indent}#{build_phase_begin}"
  file.puts "#{indent*2}#{build_super}"
  uvm_model_array.each do |item|
    if(item.agent("multi")=="y")then
      #tmp = "#{item.agent("inst")}s"
      tmp = "#{item.agent("inst")}"
      file.puts "#{item.indent*2}#{tmp} = new[num_#{tmp}];"
      file.puts "#{item.indent*2}for(int i=0; i<num_#{tmp}; i++)begin"
      file.puts "#{item.indent*3}#{tmp}[i] = #{item.agent("class")}::type_id::create\(\$sformatf\(\"#{tmp}[%0d]\", i\), this\);"
      file.puts "#{item.indent*2}end"
    else
      file.puts "#{indent*2}#{item.agent("inst")} = #{item.agent("class")}::type_id::create(\"#{item.agent("inst")}\", this);"
    end
  end
  file.puts "#{indent}#{build_phase_end}"

  file.puts ""
  file.puts "endclass"
  file.puts "`endif"
}

#### create uvm_agent(s), driver, monitor and sequencer
uvm_model_array.each do |item|
  ### uvm_agent
  open("#{dir_model_body}/#{item.agent("class")}.sv", "w") {|file|
    file.puts "`ifndef #{item.agent("class").upcase}"
    file.puts "`define #{item.agent("class").upcase}"
    file.puts "class #{item.agent("class")} extends uvm_agent;"
    file.puts ""
    file.puts "#{item.indent}#{item.driver("class")} #{item.driver("inst")};"
    file.puts "#{item.indent}#{item.sequencer("class")} #{item.sequencer("inst")};"
    file.puts "#{item.indent}#{item.monitor("class")} #{item.monitor("inst")};"
    file.puts ""
    file.puts "#{item.indent}`uvm_component_utils(#{item.agent("class")})"
    file.puts ""
    file.puts "#{item.indent}#{new_begin("uvm_component")}"
    file.puts "#{item.indent*2}super.new(name,parent);"
    file.puts "#{item.indent}#{new_end}"
    file.puts ""
    file.puts "#{item.indent}#{build_phase_begin}"
    file.puts "#{item.indent*2}#{build_super}"
    file.puts "#{item.indent*2}if(get_is_active()==UVM_ACTIVE)begin"
    file.puts "#{item.indent*3}#{item.driver("inst")} = #{item.driver("class")}::type_id::create(\"#{item.driver("inst")}\",this);"
    file.puts "#{item.indent*3}#{item.sequencer("inst")} = #{item.sequencer("class")}::type_id::create(\"#{item.sequencer("inst")}\",this);"
    file.puts "#{item.indent*2}end"
    file.puts "#{item.indent*2}#{item.monitor("inst")} = #{item.monitor("class")}::type_id::create(\"#{item.monitor("inst")}\",this);"
    file.puts "#{item.indent}#{build_phase_end}"
    file.puts ""
    file.puts "#{item.indent}#{connect_phase_begin}"
    file.puts "#{item.indent*2}if(get_is_active()==UVM_ACTIVE)"
    file.puts "#{item.indent*3}driver.seq_item_port.connect(sequencer.seq_item_export);"
    file.puts "#{item.indent}#{connect_phase_end}"
    file.puts ""
    file.puts "endclass"
    file.puts "`endif"
  }

  ### uvm_driver
  class_name = item.driver("class")
  seq_item   = item.seq_item
  open("#{dir_model_body}/#{class_name}.sv", "w") {|file|
    file.puts "`ifndef #{class_name.upcase}"
    file.puts "`define #{class_name.upcase}"
    file.puts "class #{class_name} extends uvm_driver \#(#{seq_item});"
    file.puts ""

    if(item.vif_name!="")then
      file.puts "#{item.indent}virtual #{item.vif_name} vif;"
    end

    file.puts "#{item.indent}`uvm_component_utils(#{class_name})"
    file.puts ""
    file.puts "#{item.indent}#{new_begin("uvm_component")}"
    file.puts "#{item.indent*2}super.new(name,parent);"
    file.puts "#{item.indent}#{new_end}"
    file.puts ""
    file.puts "#{item.indent}#{build_phase_begin}"
    file.puts "#{item.indent*2}#{build_super}"
    file.puts item.vif_code
    file.puts "#{item.indent}#{build_phase_end}"
    file.puts ""
    file.puts "#{item.indent}#{run_phase_begin}"
    file.puts "#{item.indent*2}@(posedge vif.rstz); /// wait for 1st reset-negate"
    file.puts "#{item.indent*2}forever begin"
    file.puts "#{item.indent*3}seq_item_port.get_next_item(req);"
    file.puts "#{item.indent*3}@(posedge vif.clk);  /// clk sync"
    file.puts "#{item.indent*3}vif.addr <= req.addr;"
    file.puts "#{item.indent*3}vif.data <= req.data;"
    file.puts "#{item.indent*3}seq_item_port.item_done();"
    file.puts "#{item.indent*2}end"
    file.puts "#{item.indent}#{run_phase_end}"
    file.puts ""
    file.puts "endclass"
    file.puts "`endif"
  }

  ### uvm_monitor
  class_name = item.monitor("class")
  open("#{dir_model_body}/#{class_name}.sv", "w") {|file|
    file.puts "`ifndef #{class_name.upcase}"
    file.puts "`define #{class_name.upcase}"
    file.puts "class #{class_name} extends uvm_monitor;"
    file.puts ""

    if(item.vif_name!="")then
      file.puts "#{item.indent}virtual #{item.vif_name} vif;"
    end

    file.puts "#{item.indent}`uvm_component_utils(#{class_name})"
    file.puts ""
    file.puts "#{item.indent}#{new_begin("uvm_component")}"
    file.puts "#{item.indent*2}super.new(name,parent);"
    file.puts "#{item.indent}#{new_end}"
    file.puts ""
    file.puts "#{item.indent}#{build_phase_begin}"
    file.puts "#{item.indent*2}#{build_super}"
    file.puts item.vif_code
    file.puts "#{item.indent}#{build_phase_end}"
    file.puts ""
    file.puts "#{item.indent}#{run_phase_begin}"
    file.puts "#{item.indent*2}forever begin"
    file.puts "#{item.indent*3}///@(posedge vif.clk);"
    file.puts "#{item.indent*3}@(vif.addr);"
    file.puts "#{item.indent*3}uvm_report_info(\"MON\", $sformatf(\"addr=%08xh\", vif.addr));"
    file.puts "#{item.indent*3}uvm_report_info(\"MON\", $sformatf(\"data=%08xh\", vif.data));"
    file.puts "#{item.indent*2}end"
    file.puts "#{item.indent}#{run_phase_end}"
    file.puts ""
    file.puts "endclass"
    file.puts "`endif"
  }

  ### uvm_sequencer
  class_name = item.sequencer("class")
  seq_item   = item.seq_item
  open("#{dir_model_body}/#{class_name}.sv", "w") {|file|
    file.puts <<"HERE"
`ifndef #{class_name.upcase}
`define #{class_name.upcase}
class #{class_name} extends uvm_sequencer \#(#{seq_item});

#{item.indent}`uvm_component_utils(#{class_name})

#{item.indent}#{new_begin("uvm_component")}
#{item.indent*2}super.new(name,parent);
#{item.indent}#{new_end}

endclass
`endif
HERE
  }
  ### uvm_sequence_item (sample)
  class_name = item.seq_item
  open("#{dir_model_body}/#{class_name}.sv", "w") {|file|
    file.puts <<"HERE"
`ifndef #{class_name.upcase}
`define #{class_name.upcase}
class #{class_name} extends uvm_sequence_item;
#{item.indent}logic [31:0] addr, data;
#{item.indent}`uvm_object_utils(#{class_name})

#{item.indent}#{new_begin("uvm_object", "#{class_name}_inst")}
#{item.indent*2}super.new(name);
#{item.indent}#{new_end}

endclass
`endif
HERE
  }
  ### uvm_seq_base (sample)
  class_name = item.seq_lib
  open("#{dir_model_body}/#{class_name}.sv", "w") {|file|
    file.puts <<"HERE"
`ifndef #{class_name.upcase}
`define #{class_name.upcase}
virtual class #{item.model}_#{item.agent("agent")}_base_seq extends uvm_sequence \#(#{item.seq_item});
#{item.indent}function new(string name="#{class_name}");
#{item.indent*2}super.new(name);
#{item.indent*2}do_not_randomize = 1;
#{item.indent}endfunction
#{item.indent}virtual task pre_body();
#{item.indent*2}if (starting_phase!=null) begin
#{item.indent*3}`uvm_info(get_type_name(),
#{item.indent*4}$sformatf("%s pre_body() raising %s objection",
#{item.indent*5}get_sequence_path(),
#{item.indent*5}starting_phase.get_name()), UVM_MEDIUM)
#{item.indent*3}starting_phase.raise_objection(this);
#{item.indent*2}end
#{item.indent}endtask

#{item.indent}// Drop the objection in the post_body so the objection is removed when
#{item.indent}// the root sequence is complete.
#{item.indent}virtual task post_body();
#{item.indent*2}if (starting_phase!=null) begin
#{item.indent*3}`uvm_info(get_type_name(),
#{item.indent*4}$sformatf("%s post_body() dropping %s objection",
#{item.indent*5}get_sequence_path(),
#{item.indent*5}starting_phase.get_name()), UVM_MEDIUM)
#{item.indent*3}starting_phase.drop_objection(this);
#{item.indent*2}end
#{item.indent}endtask

endclass

///-----------------------------------------------------------------
class #{item.agent("agent")}_sample_seq extends #{item.model}_#{item.agent("agent")}_base_seq;

#{item.indent}`uvm_object_utils(#{item.agent("agent")}_sample_seq)

#{item.indent}function new (string name="#{item.agent("agent")}_sample_seq");
#{item.indent*2}super.new(name);
#{item.indent}endfunction : new

#{item.indent}virtual task body;
#{item.indent*2}repeat(10)begin
#{item.indent*3}`uvm_create(req)
#{item.indent*3}req.addr = $urandom;
#{item.indent*3}req.data = $urandom;
#{item.indent*3}`uvm_send(req)
#{item.indent*2}end
#{item.indent}endtask : body

endclass

`endif
HERE
  }
  ### interface (sample)
  filename = item.vif_name
  open("#{dir_model_body}/#{filename}.sv", "w") {|file|
    file.puts <<"HERE"
interface #{item.vif_name}(input logic clk, rstz);
#{item.indent}logic [31:0] addr, data;
endinterface
HERE
  }
  ### "model_name"_model.svh
  filename = "#{item.model}_model.svh"
  open("#{dir_model_body}/#{filename}", "a") {|file|
    file.puts <<"HERE"
`include "#{item.seq_item}.sv"
`include "#{item.seq_lib}.sv"
`include "#{item.driver("class")}.sv"
`include "#{item.sequencer("class")}.sv"
`include "#{item.monitor("class")}.sv"
`include "#{item.agent("class")}.sv"
HERE
  }
end
### "model_name"_model.svh
filename = "#{model_name}_model.svh"
open("#{dir_model_body}/#{filename}", "a") {|file|
  file.puts <<"HERE"
`include "#{model_name}_env.sv"
HERE
}




#--------------------------------------------------------------------
#-- create testbench
#--------------------------------------------------------------------
### tb_env.sv
filename = "tb_env.sv"
open("#{dir_model_tb}/#{filename}", "w") {|file|
  file.puts <<"HERE"
`ifndef TB_ENV
`define TB_ENV
class tb_env extends uvm_env;

  /// Instanced several model Env
  #{model_name}_env #{model_name};

  /// Instanced Verification Components
  ///   - scoreboard
  ///   - monitor
  ///   - virtual sequencer, etc...

  ///////////////////////////////////////////////////////////////
  `uvm_component_utils(tb_env)
  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
HERE
uvm_model_array.each do |item|
  if item.agent("multi")=="y" then
    file.puts "#{item.indent*2}uvm_config_db#(int)::set(this, \"#{model_name}\", \"num_#{item.agent("inst")}*\", 1);"
  end
end

file.puts <<"HERE"
    #{model_name} = #{model_name}_env::type_id::create("#{model_name}", this);
  endfunction : build_phase
  function void connect_phase(uvm_phase phase);
    /// connect a scoreboard to a monitor
    /// connect model's sequencer to "sequencer in the virtual_sequencer"
  endfunction : connect_phase
endclass
`endif
HERE
}


filename = "test_lib.svh"
open("#{dir_model_tb}/#{filename}", "w") {|file|
  file.puts <<"HERE"
`ifndef TEST_LIB
`define TEST_LIB
`define set_seq(INST,SEQ) \\
  uvm_config_db#(uvm_object_wrapper)::set(this,`"INST`","default_sequence",SEQ::type_id::get());

`define uvm_test_head(NAME) \\
  class NAME extends base_test; \\
    `uvm_component_utils(NAME) \\
    function new (string name=`"NAME`", uvm_component parent=null); \\
      super.new(name,parent); \\
    endfunction
///-------------------------------------------------------------------------------------------
virtual class base_test extends uvm_test;
  tb_env tb;
  function new (string name="base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tb = tb_env::type_id::create("tb", this);
  endfunction
  task run_phase(uvm_phase phase);
    uvm_top.print_topology();
  endtask : run_phase
endclass
///-------------------------------------------------------------------------------------------
`uvm_test_head(sample_test)
  function void build_phase(uvm_phase phase);
HERE
  cnt = 0
  uvm_model_array.each do |item|
    str = ""
    str = "[#{cnt}]" if(item.agent("multi")=="y")
    file.puts "#{item.indent*2}`set_seq(tb.#{model_name}.#{item.agent("inst")}#{str}.#{item.sequencer("inst")}.run_phase, #{item.agent("agent")}_sample_seq)"
    cnt = cnt + 1
  end

  file.puts <<"HERE"
    super.build_phase(phase);
  endfunction : build_phase 
endclass
`endif
HERE
}
### tb_top.sv
filename = "tb_top.sv"
open("#{dir_model_tb}/#{filename}", "w") {|file|
  file.puts <<"HERE"
`timescale 1ps/1ps
module tb_top;
  /// UVM Class Libraries
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  /// Models
  `include "#{model_name}_model.svh"

  /// UVM Sequence libraries

  /// UVM TB
  `include "tb_env.sv"
  `include "test_lib.svh"

  ////////////////////////////////////////////////////
  /// clk, rstz
  logic clk,rstz;

  /// interface
HERE

  uvm_model_array.each do |item|
    file.puts "  #{item.vif_name} i_#{item.vif_name}(clk,rstz);"
  end

  file.puts <<"HERE"

  initial begin
    clk <= 1'b1;
    #100;
    forever #50 clk <= ~clk;
  end
  // rstz
  initial begin
    rstz     <= 1'b0;
    #80 rstz <= 1'b1;
  end

  initial begin
HERE

  uvm_model_array.each do |item|
    file.puts "    uvm_config_db#(virtual #{item.vif_name})::set(uvm_root::get(), \"*.#{item.model_name}.*\", \"vif\", i_#{item.vif_name});"
  end

  file.puts <<"HERE"
    run_test();
  end

endmodule
HERE
}
