$(./webtank_list.sh) && $(dmd show_modr.d `cat webtank.list` -op) \
&& $(cp ./show_modr /home/test_serv/web_projects/mkk_site/cgi-bin/ )