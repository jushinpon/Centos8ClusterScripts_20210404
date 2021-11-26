my @temp = `find /home/ -maxdepth 1 -mindepth 1 -type d -name "*"`;
chomp (@temp);
for (@temp){
	if(/\/home\/(.+)/){
		print "$_ $1\n";		
		`usermod -g student $1`;
		
		};
}
