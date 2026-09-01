syntax match javaPackagePath "\<package\s\+\zs\%(\h\w*\.\)*\h\w*\ze\s*;"
syntax match javaImportPath "\<import\%\(\s\+static\)\?\s\+\zs\%(\h\w*\.\)*\%(\h\w*\|\*\)\ze\s*;"

syntax match javaUserType "\<[A-Z][A-Za-z0-9_$]*\>"
syntax match javaUserMethod "\<\%(if\>\|for\>\|while\>\|switch\>\|catch\>\|synchronized\>\|try\>\)\@![$A-Za-z_][0-9A-Za-z_$]*\ze\s*("

highlight def link javaPackagePath Include
highlight def link javaImportPath Include
highlight def link javaUserType Type
highlight def link javaUserMethod Function
