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

require 'optparse'

ProgName = 'DanPenKun'
Version = '0.00'
DANPENLIBPATHNAME = "DANPENLIB"

class MyError < StandardError
end

def varinit
	$danpen = {}
	$danpenlibpath = ENV[DANPENLIBPATHNAME]
	$filename = ""
	$line = 0
end

# メッセージを出力する
def print_info(level, msg)
	# TODO:警告レベルの実装

	if $filename.size == 0
		printf($stderr, "%s\n", "#{ProgName}: #{msg}")
	elsif $line == 0
		printf($stderr, "%s\n", "#{$filename}: #{msg}")
	else
		printf($stderr, "%s\n", "#{$filename}:#{$line}: #{msg}")
	end

	return true
end

# 警告メッセージを出力する
def print_warn(level, msg)
	# TODO:警告レベルの実装

	if $filename.size == 0
		printf($stderr, "%s\n", "#{ProgName} warning: #{msg}")
	elsif $line == 0
		printf($stderr, "%s\n", "#{$filename}: warning: #{msg}")
	else
		printf($stderr, "%s\n", "#{$filename}:#{$line}: warning: #{msg}")
	end

	return true
end

# エラーメッセージを出力して終了する
def print_error(level, msg)
	if $filename.size == 0
		raise MyError, "#{ProgName} error: #{msg}"
	elsif $line == 0
		raise MyError, "#{$filename}: error: #{msg}"
	else
		raise MyError, "#{$filename}:#{$line}: error: #{msg}"
	end
end

## Windows環境下かどうか判定する
#def os_is_windows
#	return RUBY_PLATFORM.downcase =~ /(ms|cyg|bcc)win(?!ce)|mingw/
#end

def determine_encode(filename)
	false
end

def load_danpenlib_1(filename)
	determine_encode(filename)

	# TODO:エンコードの処理
	# TODO:エラー処理
	# TODO:バイナリ(.exeなど)を読んでも落ちないように

	$filename = filename
	$line = 0
	infile = File.open(filename)

	aline = infile.readline

	flag = {}
	library_name = ""
	begin_mark = ""
	paste_begin_mark = ""
	end_mark = ""

	# BUG:先頭10行程度を見る

	if aline =~ /^(.*)\sdanpenlib\s*:(.*)$/
		begin_mark = $1.strip
		library_name = $2.strip
	end

	if begin_mark == ""
		print_warn(0, "Not danpenlib")
		return false
	end

	print_info(0, "Reading library \"#{library_name}\"")

	danpen_name = ""
	state = :header
	infile.each_line do |aline|
		aline = aline.chomp
		$line = $line + 1

		if aline.strip =~ /^#{Regexp.escape(begin_mark)}(.*)#{Regexp.escape(end_mark)}$/
			s = $1.strip

			if s.size == 0
				state = :gap
			elsif s =~ /^danpendef\s*:(.*)$/
				s = $1.strip

				if s.size == 0
					print_error(0, "Missing danpen name")
				else
					if s =~ /^(\S+)\s*\((.*)\)$/
						danpen_name = $1
						section_option = $2.strip
					elsif s =~ /^(\S+)$/
						danpen_name = $1
						section_option = ""
					else
						print_error(0, "Danpendef syntax error: #{aline}")
					end

					# TODO: dup check

					print_info(0, "Reading danpen: #{danpen_name}")
					$danpen[danpen_name] = { :name => danpen_name, :body => [], :flag => flag }
					state = :danpendef
				end
			else
				print_error(0, "Danpenlib syntax error: #{aline}")
			end
		else
			case state
			when :header
				s = aline.strip
				if s.size == 0
					# NOP
				elsif s =~ /^(\w+)\s*:(.*)$/
					k = $1.strip
					v = $2.strip
					flag[k] = v

					# TODO:ちゃんと処理する
					case k
					when "Coding"
					when "Paste_Begin_Mark"
						paste_begin_mark = v
					when "End_Mark"
						end_mark = v
						state = :gap
					end
				else
					print_error(0, "Danpenlib syntax error: #{aline}")
				end
			when :danpendef
				if aline.strip =~ /^#{Regexp.escape(paste_begin_mark)}(.*)#{Regexp.escape(end_mark)}$/
					s = $1.strip
					$danpen[danpen_name][:body].push({ :type => :danpen, :val => s })
				else
					$danpen[danpen_name][:body].push({ :type => :text, :val => aline })
				end
			when :gap
				# NOP
			else
				# Unreachable
				print_error(0, "Undefined State: #{state.to_s}")
			end
		end
	end

	infile.close
	$filename = ""

	return true
end

# $danpenlibpath を見て断片ライブラリを順番に読み込む
def load_danpenlib
	if $danpenlibpath == nil
		print_error(0, "Missing environment variable: #{DANPENLIBPATHNAME}")
	end

	if File::ALT_SEPARATOR != nil
		$danpenlibpath = $danpenlibpath.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
	end

	$danpenlibpath.split(File::PATH_SEPARATOR).each do |a_path|
		if a_path.size > 0
			if File.directory?(a_path)
				Dir.foreach(a_path) do |a_file|
					if File.file?(a_file)
						load_danpenlib_1(a_file)
					end
				end
			else
				Dir.glob(a_path) do |a_file|
					if File.file?(a_file)
						load_danpenlib_1(a_file)
					end
				end
			end
		end
#		print_error(0, "Danpenlib not found: #{a_path}")
	end

	true
end

# 断片展開処理本体
def do_danpen(file)
	false
end

# コマンドラインオプションを解釈する
def parse_option
	# TODO: 未完成

	false
end

def main()
	begin

		varinit

		parse_option

		load_danpenlib

		# TODO: show_danpenlib

		do_danpen(nil)

	rescue MyError => eo
		printf($stderr, "%s\n", eo.message)
		return 1
	end

	return 0
end

exit main

