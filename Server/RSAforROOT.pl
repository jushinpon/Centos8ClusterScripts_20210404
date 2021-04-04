=beg
This script developed by Prof. Shin-Pon Ju at NSYSU (11/11/2019)
=cut

#!/usr/bin/perl
#$newuser='test'; 
use Expect;  

#########################
 print "\n$nodes if print is not a number please ctrl c \n";    # !!!!  YOU HAVE TO MAKE SURE THAT THE nodes IS CORRECT !!!! 
 ########################
chomp $nodes;
$nodes=14; #totalnodes+1
#######################################################################
$severIP ='140.117.59.191';# sever IP                                 #
$yourPASSWD ='123';               #main edit area                     #
$nodeIP = '192.168.0.101';                                               #
#######################################################################

    $exp = Expect->new;
    $exp = Expect->spawn("ssh -l root $severIP");
    $exp->expect(5,[
                        'Are.+',
                        sub {
                                my $self = shift ;
                                   $self->send("yes\n");					        
                                   exp_continue;
                            }
                    ],
                    [
                        'root@140',
                        sub{
                            my $self = shift;
                               $self ->send("MEM4268ju?#*\n");
                               exp_continue;
                            }
                    ] 
                    );
              
    $exp->send ("ssh-keygen -t rsa\n") if($exp->expect(undef,'#')); 
    $exp->expect(3,['Enter file .+',
        sub {    
                my $self = shift;
                $self->send("\n");
                exp_continue;
            }
            ],
            [
                'Overwrite',
        sub {    
                my $self = shift;
                $self->send("y\n");
                exp_continue;
            }
            ],
            [
                'Enter passphrase .+',
        sub {    
                my $self = shift;
                $self->send("\n");
                exp_continue;
            }
            ],
            [
                    'Enter same .+',
        sub {    
                my $self = shift;
                $self->send("\n");
                exp_continue;
                }
            ],
            [
                qr/connecting \(yes\/no\)/i,
		sub {
				my $self = shift ;
				$self->send("yes\n");	#first time to ssh into this node				        
				#Are you sure you want to continue connecting (yes/no)?
			}
            ]
    );
  
    $exp->send ("cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys\n"); 
   $exp->expect(2,['cp:',
        sub {    
                my $self = shift;
                $self->send("y\n");
                exp_continue;
            }
            ]);
    $exp->send ("cp /root/.ssh/authorized_keys /home/\n");
      $exp->expect(2,['cp:',
        sub {    
                my $self = shift;
                $self->send("y\n");
                exp_continue;
            }
            ]);
            foreach (2..$nodes)
            {
    $exp = Expect->spawn("ssh -l root $nodeIP$_");
    $exp->expect(6,[
                        qr/root@\d+/i,
                        sub {
                                my $self = shift ;
                                   $self->send("$yourPASSWD\n");					        
                                   exp_continue;
                            }
                    ],
                    [
                            qr/password/i,
                            sub 
                                {
                                    my $self = shift ;
                                   $self->send("$yourPASSWD\n");					        
                                   exp_continue;    
                                }
                    ],
            [
                qr/connecting \(yes\/no\)/i,
		sub {
				my $self = shift ;
				$self->send("yes\n");	#first time to ssh into this node				        
				#Are you sure you want to continue connecting (yes/no)?
			}
            ]
                    );
$exp->send ("ssh-keygen -t rsa\n")  if ($exp->expect(undef,'#')); 
 $exp->expect(3,['Enter file .+',
        sub {    
                my $self = shift;
                $self->send("\n");
                exp_continue;
            }
            ],
            [
                'Overwrite',
        sub {    
                my $self = shift;
                $self->send("y\n");
                exp_continue;
            }
            ],
            [
                'Enter passphrase .+',
        sub {    
                my $self = shift;
                $self->send("\n");
                exp_continue;
            }
            ],
            [
                    'Enter same .+',
        sub {    
                my $self = shift;
                $self->send("\n");
                exp_continue;
                }
            ]
    );
$exp ->send ("exit\n");
 $exp->expect(3,['Enter file .+',
        sub {    
                my $self = shift;
                $self->send("\n");
                exp_continue;
            }
 ]
  ); }
        $exp->soft_close();
foreach (2..$nodes)
{
      $exp2 = Expect->new;  
                $exp2 = Expect->spawn("ssh -l root $nodeIP$_");   
                $exp2->expect(5,[
                        'Are.+',
                        sub {
                                my $self = shift ;
                                   $self->send("yes\n");					        
                                   exp_continue;
                            }
                    ],
                    [
                        'password',
                        sub{
                            my $self = shift;
                               $self ->send("$yourPASSWD\n");
                               exp_continue;
                            }
                    ] 
                    ); 
                $exp2 ->send ("cp /home/authorized_keys /root/.ssh/authorized_keys\n");
                $exp2 ->expect(3,['cp',
                sub {    
                my $self = shift;
                $self->send("y\n");

                exp_continue;
            }
            ]);
               
}
                 $exp2->soft_close();  
                
        
            

