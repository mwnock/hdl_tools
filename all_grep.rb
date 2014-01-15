#!/usr/bin/ruby -w

debug     = 0
keyword   = ARGV[0]
directory = ARGV[1]
extension = ARGV[2]

skip_comment_sw = 1
skip_comment = "//"
#skip_comment = "--"

if(keyword==nil)then
  puts "*E, No keyword is found."
  exit
elsif(keyword=="-c")then
  printf "*I Entering command line mode.\n"
  printf "   Search key = ? "
  keyword = STDIN.gets.chomp
end

if(directory==nil)then
  directory = "."
end

directory += "/"

if(extension==nil)then
  extension = "*"
else
  extension = "*." + extension
end

class CheckFile
  def self.binary?(name)
    ascii = control = binary = 0

    File.open(name, "rb") {|io| io.read(1024)}.each_byte do |bt|
      case bt
        when 0...32
          control += 1
        when 32...128
          ascii += 1
        else
          binary += 1
      end
    end

    control.to_f / ascii > 0.1 || binary.to_f / ascii > 0.05
  end
end

# Dir::glob("#{directory}**/*"){ |file|
Dir::glob("#{directory}**/#{extension}"){ |file|
  if(File::ftype(file)=="directory")then
  else
    value = CheckFile::binary?(file)
    if(value==false)then
      #puts file.to_s
      open(file) do |f|
        begin
          f.each_line do |line|
            # next if(skip_comment_sw==1 && /^\s*\/\// =~ line)
            next if(skip_comment_sw==1 && /^\s*#{skip_comment}/ =~ line)
            if(/#{keyword}/ =~ line)then
              printf("%s :line %d, %s", file, f.lineno.to_s, line)
              #printf("%s :line %d, $s", file + ":line " + f.lineno.to_s
              #puts line
            end
          end
        rescue
          if(debug==1)then
            puts "*E Error detected while file search. So skip this line. File=" + \
                 "./" + file + ", skip line is " + f.lineno.to_s
            next
          end
        end

      end
    end
  end
}

