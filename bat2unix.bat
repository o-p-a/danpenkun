@rem -*- mode:Ruby; tab-width:4; coding:UTF-8; -*-
@rem vi:set ft=ruby ts=4 fenc=UTF-8 :
@ruby -x -- "%~dpn0.bat" %*
@goto :eof
[option]
arg = -x -- "${MY_ININAME}"${ARG}
use_path
[exec]
ruby
[end]
#----------------------------------------------------------------
#! /usr/bin/ruby
# coding: UTF-8
#----------------------------------------------------------------
# Windows向けのバッチファイルでもあるスクリプトからUNIX向けスクリプトを作成する
#
# 2011/03/29 opa
#----------------------------------------------------------------

ProgName = 'bat2unix'
Version = '1.00'

#=====dpk===== determine_encode
require 'kconv'

# nilなら別の値を返す
def nz(a, b)
	return (a.nil?) ? b : a
end

# エンコーディングを忘れ去って単なるバイト列とする
class String
	def verbatim
		self.force_encoding(Encoding::BINARY)
	end
end

# エンコードを判定(推測)する
def determine_encode(filename)
#	zwnbsp = "\ufeff"

	# 先頭部分を読み込み
	data = nz(File.read(filename, 2000, 0), "").verbatim

	# coding指定があればそれを信じる
	if data =~ /coding[:=]\s*([\w.-]+)/
		coding = $1

		case coding.upcase
		when "UTF-8"
			return "BOM|UTF-8"		if data[0..2] == "\xEF\xBB\xBF".verbatim
		when "UTF-16BE"
			return "BOM|UTF-16BE"	if data[0..1] == "\xFE\xFF".verbatim
		when "UTF-16LE"
			return "BOM|UTF-16LE"	if data[0..1] == "\xFF\xFE".verbatim
		when "UTF-32BE"
			return "BOM|UTF-32BE"	if data[0..3] == "\x00\x00\xFE\xFF".verbatim
		when "UTF-32LE"
			return "BOM|UTF-32LE"	if data[0..3] == "\xFF\xFE\x00\x00".verbatim
		end

		return coding
	end

	# BOMがあればそれを信じる
	return "BOM|UTF-32BE"		if data[0..3] == "\x00\x00\xFE\xFF".verbatim
	return "BOM|UTF-32LE"		if data[0..3] == "\xFF\xFE\x00\x00".verbatim
	return "BOM|UTF-8"			if data[0..2] == "\xEF\xBB\xBF".verbatim
	return "BOM|UTF-16BE"		if data[0..1] == "\xFE\xFF".verbatim
	return "BOM|UTF-16LE"		if data[0..1] == "\xFF\xFE".verbatim

	# いずれもなければKconvで推測する
	return Kconv.guess(data).to_s
end

#=====dpk=====

def bat2unix(filename)
	# ファイルが存在しなければこのファイルの処理をスキップ
	if !File.exist?(filename)
		printf("%s: Not exist: %s\n", ProgName, filename)
		return
	end

	# 拡張子がない場合はこのファイルの処理をスキップ
	if File.extname(filename).empty?
		printf("%s: No extname: skip: %s\n", ProgName, filename)
		return
	end

	encode = determine_encode(filename)
	infile = []
	File.open(filename, "r:#{encode}:internal") do |it|
		infile = it.readlines
	end

	# #!行を探す
	start_line = nil
	line = 0
	infile.each do |aline|
		line += 1
		if aline =~ /^#!/
			start_line = line
			break
		end
	end

	# #!行がない場合はこのファイルの処理をスキップ
	if start_line.nil?
		printf("%s: No shbang: skip: %s\n", ProgName, filename)
		return
	end

	# #!行までをスキップして出力
	infile.shift(start_line - 1)
	File.open(File.basename(filename, ".*"), "wb") do |it|
		it.write(infile.join)
	end
end

def main()
	if ARGV.empty?
		printf("usage: %s [filename...]\n", ProgName)
	else
		ARGV.each do |it|
			bat2unix(it)
		end
	end

	return 0
end

exit main

