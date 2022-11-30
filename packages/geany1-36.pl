#Perl script to Downlaod and install MPICH developed by Prof. Shin-Pon Ju
system("wget https://github.com/geany/geany/releases/download/1.36.0/geany-1.36.tar.gz");
system("tar xvzf geany-1.36.tar.gz");
chdir(./geany-1.36);
print Check "ALL DONE!\n";
close(check);	
