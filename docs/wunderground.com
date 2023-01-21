# yokohama, Japan weather
https://www.wunderground.com/history/daily/RJTT/date/2022-3-24

curl 'https://api.weather.com/v1/location/RJTT:9:JP/observations/historical.json?apiKey=e1f10a1e78da46f5b10a1e78da96f525&units=e&startDate=20220324' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:108.0) Gecko/20100101 Firefox/108.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Origin: https://www.wunderground.com' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://www.wunderground.com/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: cross-site'

