package InstallerConfig::File::Text::Writer;

use Moose;
use Term::ANSIColor;

use constant TRUE  => 1;

use constant FALSE => 0;


extends 'InstallerConfig::File::Writer';

## Singleton support
my $instance;

has 'record_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'setRecordList',
    reader   => 'getRecordList',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new InstallerConfig::File::Text::Writer(@_);

        if (!defined($instance)){

            confess "Could not instantiate InstallerConfig::File::Text::Writer";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _write_file {

    my $self = shift;
    my ($record_list) = @_;

    if (!defined($record_list)){

        $record_list = $self->getRecordList();

        if (!defined($record_list)){
            $self->{_logger}->logconfess("record_list was not defined");
        }
    }

    my $outfile = $self->_get_outfile();

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");

    print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";
    print OUTFILE "## date-created: " . localtime() . "\n";    

    foreach my $record (@{$record_list}){
        
        my $parameter_name = $record->getParameterName();
        if (!defined($parameter_name)){
            $self->{_logger}->logconfess("parameter_name was not defined for record: ". Dumper $record);
        }

        my $separator = $record->getSeparator();
        if (!defined($separator)){
            $self->{_logger}->logconfess("separator was not defined for record: ". Dumper $record);
        }

        my $value = $record->getAnswer();
        if (!defined($value)){
            $self->{_logger}->logconfess("value was not defined for record: ". Dumper $record);
        }

        print OUTFILE $parameter_name . $separator . $value . "\n";
    }

    close OUTFILE;

    print "\n\nWrote output configuration file ";
    printGreen("$outfile\n");
    
    $self->{_logger}->info("Wrote output configuration file '$outfile'");
    
}


sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 InstallerConfig::File::Text::Writer
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use InstallerConfig::File::Text::Writer;
 my $writer = InstallerConfig::File::Text::Writer::getInstance();
 $writer->writeFile();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut