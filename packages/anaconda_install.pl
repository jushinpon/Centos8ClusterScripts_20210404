
#`yum install libXcomposite libXcursor libXi libXtst libXrandr alsa-lib mesa-libEGL libXdamage mesa-libGL libXScrnSaver -y`;
##`rm -f anaconda.sh`;
##system("wget https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh -O ~/anaconda.sh");
#`rm -rf /opt/anaconda3`;
#system("bash ~/anaconda.sh -b -p /opt/anaconda3");
#
### install chrome browser
#system("wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm");
#system("yum install -y ./google-chrome-stable_current_x86_64.rpm");
#system("google-chrome --version");
#print "You need go to https://googlechromelabs.github.io/chrome-for-testing/#stable to install the webdriver with the same version.\n";

### The required modules in base
#system("pip install --no-input selenium");

#### make all lines and do the following for installing chrome web driver!
#### get the chrome version first by google-chrome --version
`sudo dnf install -y libXScrnSaver libappindicator-gtk3 gtk3 mesa-libgbm alsa-lib mesa-libGL`;
`rm -f chromedriver-linux64.zip`;
`rm -rf chromedriver-linux64`;
system("wget https://storage.googleapis.com/chrome-for-testing-public/129.0.6668.58/linux64/chromedriver-linux64.zip");
system("unzip chromedriver-linux64.zip");
`rm -f  /opt/webdriver/*`;
system("cp -r ./chromedriver-linux64/* /opt/webdriver/ ");
print "!!!google-chrome --version:\n";
system("google-chrome --version");
print "###chromedriver --version:\n";
system("/opt/webdriver/chromedriver --version");
