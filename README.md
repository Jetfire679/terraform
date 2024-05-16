# terraform

comby -stdin -stdout -matcher . ':[first_line]\n:[rest]' 'New first line\n:[rest]' < input.txt > output.txt
