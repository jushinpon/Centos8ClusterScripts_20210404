$OvitoURL = 'http://www.ovito.org/download/2.9.0/ovito-2.9.0-x86_64.tar.gz';
$PatchURL1 = 'http://www.ovito.org/download/2.9.0/libstdc++.so.6';
$PatchURL2 = 'http://www.ovito.org/download/2.9.0/libstdc++.so.6.0.21';
@Environmentalvariables = ('export OVITO_HOME=/home/ovito-2.9.0-x86_64/','export PATH=$OVITO_HOME/bin:$PATH'); 
############################## Download Ovito Package
@package = ("$OvitoURL","$PatchURL1","$PatchURL2");
foreach (@package)
    {
       system ("wget -P /opt/ $_");
    }
system ("cd /opt/\n tar xvf /opt/ovito-2.9.0-x86_64.tar.gz");
################################################################################## patch、driver... install
system ("cp /opt/libstdc++.so.6.0.21 /opt/ovito-2.9.0-x86_64/lib/ovito/");
system ("cp /opt/libstdc++.so.6 /opt/ovito-2.9.0-x86_64/lib/ovito/");
system ("yum -y install kernel-devel");
system ("yum -y groupinstall \"GNOME Desktop\" \"Development Tools\""); ########### 顯卡驅動
system ("yum -y update");
#################################################################################
`echo "export OVITO_HOME=/opt/ovito-2.9.0-x86_64/" >> /etc/profile`;
`echo "export PATH=\\\$OVITO_HOME/bin:\\\$PATH" >> /etc/profile`;
system (". /etc/profile");
print "ovito install all done \:\)\n";
