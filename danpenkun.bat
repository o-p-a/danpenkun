@rem vim:set ft=Ruby : -*- coding:UTF-8 mode:Ruby -*-
@ruby -x -- "%~dpn0.bat" %*
@goto :eof
[option]
arg = -x -- "${MY_ININAME}"${ARG}
use_path
[exec]
ruby
[end]
--------------------------------------------------------
#! /usr/bin/ruby
# coding: UTF-8

# 断片くん
#
# 2011/03/01 opa

class MyError < StandardError
end

def print_info(s)
       printf("%s\n", s)
end

def print_warn(s)
end

def print_error(s)
end

def varinit
       $danpen = {}
       $danpenlibpath = ""
       $filename = ""
       $line = ""
end

def parse_option
       false
end

def determine_encode(filename)
       false
end

def load_danpenlib_1(filename)
       determine_encode(filename)

       infile = File.open(filename)

       aline = infile.readline

       flag = {}
       separator = ""
       library_name = ""
       begin_mark = ""

       # BUG:先頭10行程度を見る

       if aline =~ /^(\S+)\s+danpenlib\s*:(.*)$/i
               separator = $1.strip
               library_name = $2.strip
       end

       if separator == ""
               # TODO: エラー全般にファイル名と行番号表示
               p filename + ": is not danpenlib"
               return false
       end

       print_info(sprintf("Reading library: %s", library_name))

       danpen_name = ""
       state = "header"
       infile.each_line do |aline|
               aline = aline.chomp

               if aline =~ /^#{Regexp.escape(separator)}(.*)$/
                       s = $1.strip
                       if s =~ /^danpendef\s*:(.*)$/i
                               s = $1.strip

                               if s.size == 0
                                       raise MyError, "Missing danpen name"
                               else
                                       if s =~ /^(\S+)\s*\((.*)\)\s*$/
                                               danpen_name = $1.strip
                                               section_option = $2.strip
                                       elsif s =~ /^(\S+)\s*$/
                                               danpen_name = $1.strip
                                               section_option = ""
                                       else
                                               # 現仕様ではUnreachable?
                                               raise MyError, sprintf("Danpendef syntax error: %s", s)
                                       end

                                       # TODO: dup check

#                                       printf("Reading danpen: %s\n", danpen_name)
                                       state = "danpendef"

                                       $danpen[danpen_name] = { :name => danpen_name, :body => [], :flag => flag }
                               end
                       elsif s == ""
                               state = "gap"
                       end
               else
                       case state
                       when "header"
                               if aline =~ /^\s*(\w+)\s*:(.*)$/
                                       k = $1.strip
                                       v = $2.strip
                                       flag[k] = v

                                       # TODO:ちゃんと処理する
                                       case k
                                       when "Coding"
                                       when "Begin_Mark"
                                               begin_mark = v
                                       when "Begin_Refer"
                                               begin_mark = v
                                       when "Snippet_Begin"
                                               begin_mark = v
                                       end
                               else
                                       sprintf("Danpenlib syntax error: %s", s)
                               end
                       when "danpendef"
                               if aline =~ /^#{Regexp.escape(begin_mark)}\s+(\S+)/
                                       $danpen[danpen_name][:body].push({ :type => :danpen, :val => $1.strip })
                               else
                                       $danpen[danpen_name][:body].push({ :type => :text, :val => aline })
                               end
                       when "gap"
                               # TODO:無視することでよい?
                       else
                               raise MyError, "Unknown State"
                       end
               end
       end

       infile.close

       return true
end

def load_danpenlib
       # TODO: パスの検索とワイルドカード展開してライブラリを全て読み込む
       load_danpenlib_1("string.danpen.cpp")

       # TODO: show_danpenlib

       true
end

def do_danpen
       false
end

def main()
       begin

               varinit

               parse_option

               load_danpenlib

               do_danpen

       rescue MyError => eo
               printf("%s\n", eo.message)
               return 1
       end

       return 0
end

exit main
