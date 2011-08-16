@pushd "%~dp0"
@setlocal
::
@set "BASE=danpenkun"
@set "TGT=sfjp"
::
copy "%BASE%"		"%TGT%"
copy "%BASE%.exe"	"%TGT%"
::
@endlocal
@popd
pause
