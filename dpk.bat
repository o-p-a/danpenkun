@rem vi:set ft=Ruby ts=4 : -*- coding:UTF-8 mode:Ruby -*-
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
# 断片くんドライバ
#
# 2011/04/18 opa
#----------------------------------------------------------------

ProgName = 'dpk'
Version = '0.01'
DANPENLIBPATHNAME = "DANPENLIB"

def main
	ul = ENV["USRLOCAL"]
	ul = "" if ul.nil?
	uld = ul + "\\document\\danpenlib"

	ft = [
		{ :ext => ".bat",		:lib => "#{uld}\\BAT" },
		{ :ext => ".cbl",		:lib => "#{uld}\\COBOL" },
		{ :ext => ".c",			:lib => "#{uld}\\CPP" },
		{ :ext => ".cpp",		:lib => "#{uld}\\CPP" },
		{ :ext => ".ch",		:lib => "#{uld}\\CPP" },
		{ :ext => ".js",		:lib => "#{uld}\\javascript" },
		{ :ext => ".jsee",		:lib => "#{uld}\\javascript" },
		{ :ext => ".rb",		:lib => "#{uld}\\ruby" },
		{ :ext => ".pl",		:lib => "#{uld}\\perl" },
	]

	# オプションとファイル名を分別する
	opts = []
	files = []
	next_is_opt = false
	ARGV.each do |av| # BUG : -- (これ以降をファイル名として扱う)を感知しない
		if next_is_opt
			opts.push(av)
			next_is_opt = false
		elsif av =~ /^-[Lmeo]/ # パラメータを取るオプション
			opts.push(av)
			next_is_opt = true
		elsif av =~ /^-/
			opts.push(av)
		else
			files.push(av)
		end
	end

	# 断片くん本体を起動する
	if files.empty?
		if !system("danpenkun", *opts)
			return 1
		end
	else
		files.each do |av|
			lib = ENV[DANPENLIBPATHNAME]

			# ライブラリの位置が環境変数で与えられていない場合、拡張子から推定する
			if lib.nil?
				ft.each do |a_ft|
					if File.extname(av) == a_ft[:ext]
						lib = a_ft[:lib]
						break
					end
				end
			end

			if lib.nil?
				printf($stderr, "#{ProgName}: cannot detarmine library path: #{av}\n")
			else
				joined_args = [opts, "--library-path=#{lib}", av].flatten
				if !system("danpenkun", *joined_args)
					return 1
				end
			end
		end
	end

	return 0
end

exit main

