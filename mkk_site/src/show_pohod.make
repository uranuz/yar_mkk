$(./webtank_list.sh) && $(dmd show_pohod.d `cat webtank.list` -op) \
&& $(cp ./show_pohod /home/test_serv/web_projects/mkk_site/cgi-bin/ )