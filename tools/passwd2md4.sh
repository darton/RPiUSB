read -s -p "password: " pass && echo -n $pass | iconv -t utf16le | openssl md4 | sed 's/(stdin)= //'
