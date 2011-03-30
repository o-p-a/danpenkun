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

# Windows向けのバッチファイルでもあるスクリプトからUNIX向けスクリプトを作成する
#
# 2011/03/29 opa

require 'kconv'

# ---------- determine_encode

# エンコードを判定(推測)する
def determine_encode(filename)
	# 先頭部分を読み込み
	data = File.read(filename, 2000, 0)
	data = "" if data.nil?
	data.force_encoding("ASCII-8BIT")

	# coding指定があればそれを信じる
	if data =~ /coding[:=]\s*([\w.-]+)/
		coding = $1

		case coding.upcase
		when "UTF-8"
			return "BOM|" + coding if data[0..2] == "\xEF\xBB\xBF".force_encoding("ASCII-8BIT")
		when "UTF-16BE"
			return "BOM|" + coding if data[0..1] == "\xFE\xFF".force_encoding("ASCII-8BIT")
		when "UTF-16LE"
			return "BOM|" + coding if data[0..1] == "\xFF\xFE".force_encoding("ASCII-8BIT")
		when "UTF-32BE"
			return "BOM|" + coding if data[0..3] == "\x00\x00\xFE\xFF".force_encoding("ASCII-8BIT")
		when "UTF-32LE"
			return "BOM|" + coding if data[0..3] == "\xFF\xFE\x00\x00".force_encoding("ASCII-8BIT")
		end

		return coding
	end

	# BOMがあればそれを信じる
	return "BOM|UTF-32BE"		if data[0..3] == "\x00\x00\xFE\xFF".force_encoding("ASCII-8BIT")
	return "BOM|UTF-32LE"		if data[0..3] == "\xFF\xFE\x00\x00".force_encoding("ASCII-8BIT")
	return "BOM|UTF-8"			if data[0..2] == "\xEF\xBB\xBF".force_encoding("ASCII-8BIT")
	return "BOM|UTF-16BE"		if data[0..1] == "\xFE\xFF".force_encoding("ASCII-8BIT")
	return "BOM|UTF-16LE"		if data[0..1] == "\xFF\xFE".force_encoding("ASCII-8BIT")

	# いずれもなければKconvで推測する
	return Kconv.guess(data).to_s
end

# ----------

def convert(filename)
	# 拡張子がない場合はスキップ
	if File.extname(filename).empty?
		printf("No extname: skip: %s\n", filename)
		return
	end

	encode = determine_encode(filename)

	infile = []
	File.open(filename, "r:#{encode}:internal") do |is|
		infile = is.readlines
	end

	start_line = nil
	line = 0
	infile.each do |aline|
		line += 1
		if aline =~ /^#!/
			start_line = line
			break
		end
	end

	if start_line.nil?
		printf("No shbang: skip: %s\n", filename)
		return
	end

	infile.shift(start_line - 1)

	File.open(File.basename(filename, ".*"), "wb") do |os|
		os.write(infile.join)
	end
end

def main()
	ARGV.each do |f|
		convert(f)
	end

	return 0
end

exit main

