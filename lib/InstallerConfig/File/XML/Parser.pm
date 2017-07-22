package InstallerConfig::File::XML::Parser;

use Moose;
use XML::Twig;

use InstallerConfig::Prompt::Record;

use constant TRUE  => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

## Singleton support
my $instance;

my $this;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'infile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfile',
    reader   => 'getInfile',
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

        $instance = new InstallerConfig::File::XML::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate InstallerConfig::File::XML::Parser";
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

sub getPromptRecordList {

    my $self = shift;

    if (! exists $self->{_record_list}){
        $self->_parse_file(@_);
    }

    return $self->{_record_list};
}

sub _parse_file {

    my $self = shift;
    my ($infile) = @_;

    if (!defined($infile)){

        $infile = $self->getInfile();

        if (!defined($infile)){
            $self->{_logger}->logconfess("infile was not defined");
        }
    }
    else {
        $self->setInfile($infile);
    }

    $this = $self;
   
    my $twig = new XML::Twig(
    twig_handlers =>  { 
        prompt => \&promptHandler 
    }
    );

    if (!defined($twig)){
        $self->{_logger}->logconfess("Could not instantiate XML::Twig");
    }

    if ($self->getVerbose()){
        print "About to parse input file '$infile'\n";
    }

    $self->{_logger}->info("About to parse input file '$infile'");

    $twig->parsefile($infile);
}

sub promptHandler {

    my $self = $this;
    my ($twig, $promptElem) = @_;


    my $record = new InstallerConfig::Prompt::Record();
    if (!defined($record)){
        $self->{_logger}->logconfess("InstallerConfig::Prompt::Record");
    }

    if ($promptElem->has_child('desc')){
        
        my $desc = $promptElem->first_child('desc')->text();
        
        if ((defined($desc)) && ($desc ne '')){
            $record->setDesc($desc);
        }

    }

    if ($promptElem->has_child('question')){
        
        my $question = $promptElem->first_child('question')->text();
        
        if ((defined($question)) && ($question ne '')){
            $record->setPrompt($question);
        }
        else {
            $self->{_logger}->logconfess("question was not defined!");
        }
    }
    else {
        $self->{_logger}->logconfess("There is no <question> element");
    }


    if ($promptElem->has_child('parameter-name')){
        
        my $parameter_name = $promptElem->first_child('parameter-name')->text();
        
        if ((defined($parameter_name)) && ($parameter_name ne '')){
            $record->setParameterName($parameter_name);
        }
        else {
            $self->{_logger}->logconfess("parameter-name was not defined!");
        }
    }
    else {
        $self->{_logger}->logconfess("There is no <parameter-name> element");
    }


    if ($promptElem->has_child('acceptable-values')){
        
        my $acceptable_values_elem = $promptElem->first_child('acceptable-values');

        $self->_process_acceptable_values_elem($acceptable_values_elem, $record);
    }


    if ($promptElem->has_child('example-values')){
        
        my $example_values_elem = $promptElem->first_child('example-values');

        $self->_process_example_values_elem($example_values_elem, $record);
    }


    push(@{$self->{_record_list}}, $record);
}


sub _process_acceptable_values_elem {

    my $self = shift;
    my ($acceptable_values_elem, $record) = @_;

    if ($acceptable_values_elem->has_child('value')){

        my $value_elem = $acceptable_values_elem->first_child('value');

        $self->_process_acceptable_value_elem($value_elem, $record);

        while ($value_elem = $value_elem->next_sibling('value')){

            $self->_process_acceptable_value_elem($value_elem, $record);            
        }
    }
}

sub _process_acceptable_value_elem {

    my $self = shift;
    my ($value_elem, $record) = @_;

    my $value = $value_elem->text();

    if ((defined($value)) && ($value ne '')){
        $record->addAcceptableValue($value);
    }
    else {
        $self->{_logger}->logconfess("accceptable value was not defined for record " . Dumper $record);
    }
}


sub _process_example_values_elem {

    my $self = shift;
    my ($example_values_elem, $record) = @_;

    if ($example_values_elem->has_child('value')){

        my $value_elem = $example_values_elem->first_child('value');

        $self->_process_example_value_elem($value_elem, $record);

        while ($value_elem = $value_elem->next_sibling('value')){

            $self->_process_example_value_elem($value_elem, $record);            
        }
    }
}

sub _process_example_value_elem {

    my $self = shift;
    my ($value_elem, $record) = @_;

    my $value = $value_elem->text();

    if ((defined($value)) && ($value ne '')){
        $record->addExampleValue($value);
    }
    else {
        $self->{_logger}->logconfess("example value was not defined for record " . Dumper $record);
    }
}




no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 InstallerConfig::File::XML::Parser
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use InstallerConfig::File::XML::Parser;
 my $parser = new InstallerConfig::File::XML::Parser(infile => $infile);
 my $record_list = $parser->getPromptRecordList();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
