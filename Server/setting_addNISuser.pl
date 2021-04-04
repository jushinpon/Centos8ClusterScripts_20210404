=beg
This script developed by Prof. Shin-Pon Ju at NSYSU (11/11/2019)
=cut

#!/usr/bin/perl
#$newuser='test'; 
use Expect;  
#######################################################################
$severIP ='140.117.60.161';# sever IP                                 #
$yourPASSWD ='j0409leeChu?#*';               #main edit area                 #                                  #
@userlist = qw/s9811411/;   # you can add lots of user by one time !!!    #
#######################################################################
#foreach (@userlist)
#        {
#             system("adduser $_");    
#        }

foreach(@userlist)
{

    $exp = Expect->new;
    $exp = Expect->spawn("ssh -l root $severIP");
    $exp->expect(2,[
                        'connecting (yes/no)',
                        sub {
                                my $self = shift ;
                                   $self->send("yes\n");					        
                                   exp_continue;
                            }
                    ],
                    [
                        'password',
                        sub {
                                my $self = shift ;
                                   $self->send("mem4268\n");					        
                                   exp_continue;
                            }
                    ]
                );
    $exp->send ("passwd $_\n") if ($exp->expect(3,'#'));
    $exp->send ("$yourPASSWD\n") if ($exp->expect(3, -re =>'New\s+\D+'));
    $exp->send ("$yourPASSWD\n") if ($exp->expect(3, -re =>'Retype\s+\D+\s+\D+'));  
}
$exp->soft_close();
##########################################################################  CREAT USER
$exp2 = Expect->new;
foreach(@userlist)
    {
         $exp2 = Expect->spawn("ssh -l $_ $severIP");
             $exp2->expect(2,[
                            'connecting (yes/no)',
                            sub {
                                    my $self = shift ;
                                       $self->send("yes\n");					        
                                       exp_continue;
                                }
                        ],
                        [
                            'password',
                            sub {
                                    my $self = shift ;
                                       $self->send("$yourPASSWD\n");					        
                                       exp_continue;
                                }
                        ]
                    );
        $exp2->send ("ssh-keygen -t rsa\n");
        $exp2->expect(3,[
                         'Enter',
                        sub {
                                my $self = shift ;
                                   $self->send("\n");					        
                                   exp_continue;
                            }
                    ],
                    [
                        'Enter',
                        sub {
                                my $self = shift ;
                                   $self->send("\n");					        
                                   exp_continue;
                            }
                    ],
                    [
                        'Over',
                        sub {
                                my $self = shift ;
                                   $self->send("y\n");					        
                                   exp_continue;
                            }
                    ]
                );
				sleep (2);

$exp2->send("cd /home/$_/.ssh/\n"); 
$exp2->send("cp id_rsa.pub authorized\_keys\n ");          
    }
$exp2->soft_close();
#foreach(@userlist)
#    {
#system ("cp /home/$_/.ssh/id_rsa.pub /home/$_/.ssh/authorized_keys");
#}
#################################################  RSA DONE
    $exp3 = Expect->new;
    $exp3 = Expect->spawn("ssh -l root $severIP");
    $exp3->expect(2,[
                        'connecting (yes/no)',
                        sub {
                                my $self = shift ;
                                   $self->send("yes\n");					        
                                   exp_continue;
                            }
                    ],
                    [
                        'password',
                        sub {
                                my $self = shift ;
                                   $self->send("mem4268\n");					        
                                   exp_continue;
                            }
                    ]
                );

 foreach (@userlist)
    {
        
        $exp3->expect(2,[
                        'over',
                        sub {
                                my $self = shift ;
                                   $self->send("y\n");					        
                                   exp_continue;
                            }
                    ]);
		$exp3->send("chmod 700 /home/$_\n");
		$exp3->send("chmod 700 /home/$_/.ssh\n");
		$exp3->send("chmod 600 /home/$_/.ssh/authorized_keys\n");
		$exp3->send("chmod 600 /home/$_/.ssh/id_rsa.pub\n");
    }
    $exp3->send("echo -e \"\\004\" \| /usr/lib64/yp/ypinit -m\n") if ($exp3->expect(3,'#'));
    $exp3->send("systemctl restart rpcbind ypbind ypserv ypxfrd yppasswdd\n") if ($exp3->expect(3,'#'));

$exp3->soft_close();
