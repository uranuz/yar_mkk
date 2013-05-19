$(./webtank_list.sh) && $(dmd protected_page.d `cat webtank.list` -op) \
&& $(cp ./protected_page /home/test_serv/web_projects/mkk_site/cgi-bin/ )
