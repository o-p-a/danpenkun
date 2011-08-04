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
# 断片くんドライバ
#
# 2011/04/18 opa
#----------------------------------------------------------------

ProgName = 'dpk'
Version = '0.01'
DANPENLIBPATHNAME = "DANPENLIB"

def sort_opts_files(argv)
	opts = []
	files = []
	next_is_opt = false

	argv.each do |av| # BUG : -- (これ以降をファイル名として扱う)を感知しない
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

	return opts, files
end

def determine_lib(filename)
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
		{ :ext => ".htm",		:lib => "#{uld}\\javascript" },
		{ :ext => ".html",		:lib => "#{uld}\\javascript" },
		{ :ext => ".rb",		:lib => "#{uld}\\ruby" },
		{ :ext => ".pl",		:lib => "#{uld}\\perl" },
	]

	ft.each do |a_ft|
		if File.extname(filename) == a_ft[:ext]
			return a_ft[:lib]
		end
	end

	return nil
end

def main

	# オプションとファイル名をそれぞれ得る
	opts, files = sort_opts_files(ARGV)

	# 断片くん本体を起動する
	if files.empty?
		if !system("danpenkun", *opts)
			return 1
		end
	else
		files.each do |a_file|
			# ライブラリの位置が環境変数で与えられていない場合、拡張子から推定する
			lib = ENV[DANPENLIBPATHNAME]
			if lib.nil?
				lib = determine_lib(a_file)
			end

			if lib.nil?
				printf($stderr, "#{ProgName}: cannot detarmine library path: #{a_file}\n")
			else
				joined_args = [opts, "--library-path=#{lib}", a_file].flatten
				if !system("danpenkun", *joined_args)
					return 1
				end
			end
		end
	end

	return 0
end

exit main

