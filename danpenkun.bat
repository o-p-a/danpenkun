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
require 'kconv'
require 'shellwords'

ProgName = 'DanPenKun'
Version = '0.00'
DANPENLIBPATHNAME = "DANPENLIB"

# Windows環境下かどうか判定する
def os_is_windows
	return RUBY_PLATFORM.downcase =~ /(ms|cyg|bcc)win(?!ce)|mingw/
end

class MyError < StandardError
end

class Danpen_body
	def initialize(type = nil, value = nil)
		@type = type
		@value = value
	end

	attr_accessor :type, :value
end

class Danpen
	def initialize
		# 基本情報
		@name = ""
		@desc = ""
		@filename = ""
		@line = 0
		@body = []

		# オプション類
		@expand_once = false	# 一度しか展開しないかどうか

		# 展開情報
		@expand_count = 0		# 展開された回数
	end

	def reset_counter()
		@expand_count = 0
	end

	attr_accessor :name, :desc, :filename, :line, :body
	attr_accessor :expand_once
	attr_accessor :expand_count
	public :reset_counter
end

def var_init
	$stdin.set_encoding('locale:UTF-8') # EXT:INT
	$stdout.set_encoding('locale:UTF-8')
	$stderr.set_encoding('locale:UTF-8')

	$danpen = {}
	$danpenlibpath = ENV[DANPENLIBPATHNAME]
	$filename = ""
	$line = 0
	$paste_begin_mark = ""
	$end_mark = ""
	$outbuf = ""
end

# TODO:汎用私家製メッセージライブラリに置き換える

# メッセージを出力する
def print_info(level, msg)
	if $filename.empty?
		printf($stderr, "%s\n", "#{ProgName}: #{msg}")
	elsif $line == 0
		printf($stderr, "%s\n", "#{$filename}: #{msg}")
	else
		printf($stderr, "%s\n", "#{$filename}:#{$line}: #{msg}")
	end
end

# 警告メッセージを出力する
def print_warn(level, msg)
	if $filename.empty?
		printf($stderr, "%s\n", "#{ProgName} warning: #{msg}")
	elsif $line == 0
		printf($stderr, "%s\n", "#{$filename}: warning: #{msg}")
	else
		printf($stderr, "%s\n", "#{$filename}:#{$line}: warning: #{msg}")
	end
end

# エラーメッセージを出力して終了する
def print_error(level, msg)
	if $filename.empty?
		raise MyError, "#{ProgName} error: #{msg}"
	elsif $line == 0
		raise MyError, "#{$filename}: error: #{msg}"
	else
		raise MyError, "#{$filename}:#{$line}: error: #{msg}"
	end
end

# エンコードを判定(推測)する
def determine_encode(filename)
	# 先頭部分を読み込み
	data = File.read(filename, 2000, 0)
	data = "" if data == nil
	data.force_encoding("ASCII-8BIT")

	# coding指定があればそれを信じる
	if data =~ /coding[:=]\s*([\w.-]+)/
		return $1
	end

	# BOMがあればそれを信じる
	if data[0..3] == "\x00\x00\xFE\xFF".force_encoding("ASCII-8BIT")
		return "BOM|UTF-32BE"
	end
	if data[0..3] == "\xFF\xFE\x00\x00".force_encoding("ASCII-8BIT")
		return "BOM|UTF-32LE"
	end
	if data[0..2] == "\xEF\xBB\xBF".force_encoding("ASCII-8BIT")
		return "BOM|UTF-8"
	end
	if data[0..1] == "\xFE\xFF".force_encoding("ASCII-8BIT")
		return "BOM|UTF-16BE"
	end
	if data[0..1] == "\xFF\xFE".force_encoding("ASCII-8BIT")
		return "BOM|UTF-16LE"
	end

	# いずれもなければKconvで推測する
	return Kconv.guess(data).to_s
end

# 改行文字を判定(推測)する
def determine_newlinechar(filename)
	# 先頭部分を読み込み
	data = File.read(filename, 2000, 0)
	data = "" if data == nil
	data.force_encoding("ASCII-8BIT")

	# それぞれの改行の個数を数える
	crlf_count = data.scan(/\r\n/).count
	cr_count = data.scan(/\r/).count - crlf_count
	lf_count = data.scan(/\n/).count - crlf_count

	# 多数決っぽく判定する
	if crlf_count < cr_count
		if cr_count > lf_count
			return "\r" # CR
		else
			return "\n" # LF
		end
	else
		if crlf_count > lf_count
			return "\r\n" # CRLF
		elsif crlf_count < lf_count
			return "\n" # LF
		end
	end

	# どれともいえないときはOSで判定
	if os_is_windows
		return "\r\n" # CRLF
	else
		return "\n" # LF
	end
end

# 断片ライブラリをひとつ読み込む処理
def load_danpenlib_1(filename)
	$filename = filename
	$line = 0

	library_name = ""
	flag = {}
	begin_mark = ""
	paste_begin_mark = ""
	end_mark = ""
	danpen_name = ""
	state = :header

	# ファイルが読めなければエラー
	if !File.readable?(filename)
		print_error(0, "Cannot read")
	end

	# 文字コードを決定
	encode = determine_encode(filename)
	print_info(0, "Assuming encode: #{encode}")

	# とりあえず全体を読んじゃう ついでにUTF-8に統一する
	infile = []
	File.open(filename, "r:#{encode}:internal") do |is|
		infile = is.readlines

		infile.each do |aline|
			begin
				aline.encode!("UTF-8")
			rescue Encoding::UndefinedConversionError
				print_error(0, "Invalid byte sequence in #{encode}")
			end
		end
	end

	# 「danpenlib」の行があるかどうか確認
	infile.each do |aline|
		aline = aline.chomp
		$line = $line + 1

		if $line > 20
			break
		end

		if aline =~ /^(.*)\sdanpenlib\s*:(.*)$/
			begin_mark = $1.strip
			library_name = $2.strip
			break
		end
	end

	# なければdanpenlibではない → 何もせずリターン
	if begin_mark.empty?
		$line = 0
		print_warn(0, "Not danpenlib")
		return false
	end

	print_info(0, "Reading library \"#{library_name}\"")

	while $line < infile.size
		aline = infile[$line].chomp
		$line = $line + 1

		if aline.strip =~ /^#{Regexp.escape(begin_mark)}(.*)#{Regexp.escape(end_mark)}$/
			s = $1.strip

			if s.empty?
				state = :gap
			elsif s =~ /^danpendef\s*:(.*)$/
				s = Shellwords.shellwords($1)

				if s.empty?
					print_error(0, "Missing danpen name")
				else
					danpen_name = s.shift
					if $danpen.include?(danpen_name)
						print_error(0, "Duplicate danpen: #{danpen_name}")
					end

					print_info(0, "Reading danpen: #{danpen_name}")
					d = Danpen.new
					d.name = danpen_name
					d.filename = $filename
					d.line = $line

					s.each do |opt|
						case opt
						when "once"
							d.expand_once = true
						else
							print_error(0, "Danpendef syntax error: #{aline}")
						end
					end

					$danpen[danpen_name] = d
					state = :danpendef
				end
			else
				print_error(0, "Danpenlib syntax error: #{aline}")
			end
		else
			case state
			when :header
				s = aline.strip
				if s.empty?
					# NOP
				elsif s =~ /^(\w+)\s*:(.*)$/
					k = $1.strip
					v = $2.strip
					flag[k] = v

					case k
					when "paste_begin_mark"
						paste_begin_mark = v
						$paste_begin_mark = v if $paste_begin_mark.empty?
					when "end_mark"
						end_mark = v
						$end_mark = v if $end_mark.empty?
						state = :gap
					end
				else
					print_error(0, "Danpenlib header syntax error: #{aline}")
				end
			when :danpendef
				b = Danpen_body.new
				if !paste_begin_mark.empty? && aline.strip =~ /^#{Regexp.escape(paste_begin_mark)}(.*)#{Regexp.escape(end_mark)}$/
					b.type = :danpen
					b.value = $1.strip
				else
					b.type = :text
					b.value = aline
				end
				$danpen[danpen_name].body.push(b)
			when :gap
				# 無視領域: 何もしない
			else
				# Unreachable
				print_error(0, "Undefined state: #{state.to_s}")
			end
		end
	end

	$filename = ""
end

# $danpenlibpath を見て断片ライブラリを順番に読み込む
def load_danpenlib
	# ライブラリの場所が与えられていなければ警告
	if $danpenlibpath == nil
		print_warn(0, "Missing danpenlib location")
		$danpenlibpath = ""
	end

	# (例えば)Windowsの場合、"\\"を"/"に置換
	if File::ALT_SEPARATOR != nil
		$danpenlibpath = $danpenlibpath.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
	end

	$danpenlibpath.split(File::PATH_SEPARATOR).each do |a_path|
		if !a_path.empty?
			# ディレクトリなら、その中のファイルを一つづつ
			# さもなくば、ワイルドカード展開した結果を一つづつ
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
	end
end

# 出力データを蓄積
def out(s)
	$outbuf << s
end

# 断片ひとつを展開 (再帰的)
def expand_danpen(danpen_name, newlinechar)
#	print_info(0, "Expand danpen: #{danpen_name}")

	danpen = $danpen[danpen_name]
	if danpen != nil
		# いちどしか展開しない断片は、展開済であれば展開しない
		if danpen.expand_once && danpen.expand_count > 0
			print_info(0, "Already expanded, skip: #{danpen_name}")
			return
		end

		# 展開した回数を増やす
		danpen.expand_count = danpen.expand_count + 1

		# 展開する
		danpen.body.each do |b|
			case b.type
			when :text
				# TODO : ここで偶然paste_begin_markに相当する文字列だった場合の考慮
				out("#{b.value}#{newlinechar}")
			when :danpen
				expand_danpen(b.value, newlinechar)
			else
				print_error(0, "Undefined type: #{b.type.to_s} to UTF-8")
			end
		end
	else
		print_error(0, "Danpen not defined: #{danpen_name}")
	end
end

# 断片展開処理本体
def do_danpen(filename)
	$filename = filename
	$line = 0
	$outbuf = ""
	paste_begin_mark = $paste_begin_mark
	end_mark = $end_mark
	mark_str = (paste_begin_mark + " " + end_mark).strip

	# 使用回数等リセット
	$danpen.each do |k, v|
		v.reset_counter
	end

	# ファイルが読めなければエラー
	if !File.readable?(filename)
		print_error(0, "Cannot read")
	end

	print_info(0, "Danpen expand: #{filename}")
	print_info(0, "Expand mark: #{mark_str}")

	# 文字コード・改行コードを決定
	encode = determine_encode(filename)
	print_info(0, "Assuming encode: #{encode}")
	newlinechar = determine_newlinechar(filename)
	print_info(0, "Assuming newline character: #{newlinechar.dump}")

	# とりあえず全体を読む ついでにUTF-8に統一する
	infile = []
	File.open(filename, "r:#{encode}:internal") do |is|
		infile = is.readlines

		infile.each do |aline|
			begin
				aline.encode!("UTF-8")
			rescue Encoding::UndefinedConversionError
				print_error(0, "Invalid byte sequence in #{encode}")
			end
		end
	end

	# 処理本体
	state = :normal
	infile.each do |aline|
		aline = aline.chomp
		$line = $line + 1

		if !paste_begin_mark.empty? && aline.strip =~ /^#{Regexp.escape(paste_begin_mark)}(.*)#{Regexp.escape(end_mark)}$/
			danpen_name = $1.strip
			case state
			when :normal
				# この行自体はそのまま出力する
				out("#{aline}#{newlinechar}")

				# 展開内容を展開する
				if !danpen_name.empty?
					expand_danpen(danpen_name, newlinechar)
					out("#{mark_str}#{newlinechar}")
					state = :expand
				end
			when :expand
				if danpen_name.empty?
					state = :normal
				else
					print_error(0, "Missing end mark (#{mark_str})")
				end
			else
				# Unreachable
				print_error(0, "Undefined state: #{state.to_s}")
			end
		else
			case state
			when :normal
				out("#{aline}#{newlinechar}")
			when :expand
				# NOP
			else
				# Unreachable
				print_error(0, "Undefined state: #{state.to_s}")
			end
		end
	end
	$line = $line + 1

	case state
	when :normal
		# NOP
	when :expand
		print_error(0, "Missing end mark (#{mark_str})")
	else
		# Unreachable
		print_error(0, "Undefined state: #{state.to_s}")
	end
	$filename = ""

	print($outbuf)
end

# コマンドラインオプションを解釈する
def parse_option
	ARGV.options do |opt|
		opt.banner = "Usage: #{ProgName} [options] file..."

		# TODO: 未完成

		opt.parse!
	end
end

def main()
	begin

		var_init

		parse_option

		load_danpenlib

		# TODO: show_danpenlib

		ARGV.each do |a|
			do_danpen(a)
		end

	rescue MyError => eo
		printf($stderr, "%s\n", eo.message)
		return 1
	end

	return 0
end

exit main

