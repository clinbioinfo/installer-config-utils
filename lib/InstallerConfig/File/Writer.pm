package InstallerConfig::File::Writer;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;

use constant TRUE  => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_OUTFILE_BASENAME => 'installer-config-file';

## Singleton support
my $instance;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'infile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfile',
    reader   => 'getInfile',
    required => FALSE
    );

has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutfile',
    reader   => 'getOutfile',
    required => FALSE
    );

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new InstallerConfig::File::Writer(@_);

        if (!defined($instance)){

            confess "Could not instantiate InstallerConfig::File::Writer";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}


sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}

sub writeFile {

    my $self = shift;

    $self->_write_file(@_);
}

sub _get_outfile {

    my $self = shift;
    
    my $outfile = $self->getOutfile();

    
    if (!defined($outfile)){
    
        my $outdir = $self->getOutdir();
    
        $outfile = $outdir . '/' . DEFAULT_OUTFILE_BASENAME; 
    
        $self->{_logger}->warn("outfile was not defined and therefore was set to default '$outfile'");
    }

    $self->setOutfile($outfile);

    return $outfile;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 InstallerConfig::File::Writer
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use InstallerConfig::File::Writer;
 my $writer = InstallerConfig::File::Writer::getInstance();
 $writer->writeFile();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut