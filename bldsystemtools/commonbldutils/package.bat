set PATH=%PATH%;\generic\epoc32\tools
attrib -r \product\tools\*.* /s
perl \product\tools\package.pl %BuildNumber% \Product\BuildProduct.log